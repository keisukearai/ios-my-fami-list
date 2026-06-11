import Foundation

@Observable
@MainActor
final class GroupViewModel {
    var groups: [FamilyGroupBrief] = []
    var currentGroup: FamilyGroup?
    var customCategories: [GroupCategory] = []
    var isLoading = false
    var errorMessage: String?

    private var pollingTask: Task<Void, Never>?
    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

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

    func refreshAll() async {
        await fetchAll()
    }

    private func fetchAll() async {
        do {
            groups = try await api.request("\(APIClient.apiBase)/groups/")
            if let id = currentGroup?.id {
                currentGroup = try await api.request("\(APIClient.apiBase)/groups/\(id)/")
            } else if let first = groups.first {
                currentGroup = try await api.request("\(APIClient.apiBase)/groups/\(first.id)/")
            }
            await fetchCategories()
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }
    }

    func selectGroup(_ id: Int) async {
        do {
            currentGroup = try await api.request("\(APIClient.apiBase)/groups/\(id)/")
            await fetchCategories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchCategories() async {
        guard let groupId = currentGroup?.id else { return }
        if let cats = try? await api.fetchCategories(groupId: groupId) {
            customCategories = cats
        }
    }

    func createCategory(name: String, color: String) async throws {
        guard let groupId = currentGroup?.id else { return }
        let cat = try await api.createCategory(groupId: groupId, name: name, color: color)
        customCategories.append(cat)
    }

    func updateCategory(id: Int, name: String? = nil, color: String? = nil) async throws {
        guard let groupId = currentGroup?.id else { return }
        let updated = try await api.updateCategory(groupId: groupId, catId: id, name: name, color: color)
        if let idx = customCategories.firstIndex(where: { $0.id == id }) {
            customCategories[idx] = updated
        }
    }

    func deleteCategory(id: Int) async throws {
        guard let groupId = currentGroup?.id else { return }
        try await api.deleteCategory(groupId: groupId, catId: id)
        customCategories.removeAll { $0.id == id }
    }

    func createGroup(name: String) async throws {
        let group: FamilyGroup = try await api.request("\(APIClient.apiBase)/groups/", method: "POST", body: ["name": name])
        await fetchAll()
        currentGroup = group
    }

    func joinGroup(inviteCode: String) async throws {
        let group: FamilyGroup = try await api.request(
            "\(APIClient.apiBase)/groups/join/",
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
                "\(APIClient.apiBase)/groups/\(groupId)/lists/",
                method: "POST",
                body: ["name": name]
            )
            currentGroup = try await api.request("\(APIClient.apiBase)/groups/\(groupId)/")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateList(_ list: ShoppingListBrief, name: String) async {
        guard let groupId = currentGroup?.id else { return }
        do {
            let updated: ShoppingListBrief = try await api.updateList(groupId: groupId, listId: list.id, name: name)
            if let idx = currentGroup?.lists.firstIndex(where: { $0.id == list.id }) {
                currentGroup?.lists[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateGroup(id: Int, name: String) async {
        do {
            let updated: FamilyGroup = try await api.request(
                "\(APIClient.apiBase)/groups/\(id)/",
                method: "PUT",
                body: ["name": name]
            )
            if let idx = groups.firstIndex(where: { $0.id == id }) {
                groups[idx].name = updated.name
            }
            if currentGroup?.id == id { currentGroup?.name = updated.name }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteGroup(id: Int) async {
        do {
            try await api.requestVoid("\(APIClient.apiBase)/groups/\(id)/", method: "DELETE")
            groups.removeAll { $0.id == id }
            if currentGroup?.id == id { currentGroup = nil; await fetchAll() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leaveGroup(id: Int) async {
        do {
            try await api.requestVoid("\(APIClient.apiBase)/groups/\(id)/leave/", method: "POST")
            groups.removeAll { $0.id == id }
            if currentGroup?.id == id { currentGroup = nil; await fetchAll() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteList(_ list: ShoppingListBrief) async {
        guard let groupId = currentGroup?.id else { return }
        do {
            try await api.requestVoid("\(APIClient.apiBase)/groups/\(groupId)/lists/\(list.id)/", method: "DELETE")
            currentGroup = try await api.request("\(APIClient.apiBase)/groups/\(groupId)/")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
