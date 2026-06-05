import Foundation

@Observable
@MainActor
final class GroupViewModel {
    var groups: [FamilyGroupBrief] = []
    var currentGroup: FamilyGroup?
    var isLoading = false
    var errorMessage: String?

    private var pollingTask: Task<Void, Never>?
    private let api = APIClient.shared

    func start() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                await fetchAll()
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func fetchAll() async {
        do {
            groups = try await api.request("/api/fami_list/groups/")
            if let id = currentGroup?.id {
                currentGroup = try await api.request("/api/fami_list/groups/\(id)/")
            } else if let first = groups.first {
                currentGroup = try await api.request("/api/fami_list/groups/\(first.id)/")
            }
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }
    }

    func selectGroup(_ id: Int) async {
        do {
            currentGroup = try await api.request("/api/fami_list/groups/\(id)/")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createGroup(name: String) async throws {
        let group: FamilyGroup = try await api.request("/api/fami_list/groups/", method: "POST", body: ["name": name])
        await fetchAll()
        currentGroup = group
    }

    func joinGroup(inviteCode: String) async throws {
        let group: FamilyGroup = try await api.request(
            "/api/fami_list/groups/join/",
            method: "POST",
            body: ["invite_code": inviteCode]
        )
        await fetchAll()
        currentGroup = group
    }

    func createList(name: String) async {
        guard let groupId = currentGroup?.id else { return }
        do {
            let _: ShoppingListBrief = try await api.request(
                "/api/fami_list/groups/\(groupId)/lists/",
                method: "POST",
                body: ["name": name]
            )
            currentGroup = try await api.request("/api/fami_list/groups/\(groupId)/")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteList(_ list: ShoppingListBrief) async {
        guard let groupId = currentGroup?.id else { return }
        do {
            try await api.requestVoid("/api/fami_list/groups/\(groupId)/lists/\(list.id)/", method: "DELETE")
            currentGroup = try await api.request("/api/fami_list/groups/\(groupId)/")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
