import Foundation
import SwiftData

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
    private let store = LocalDataStore.shared

    init(api: APIClient = .shared) {
        self.api = api
    }

    // MARK: - Groups cache

    private static let cachedGroupsKey = "cached_groups"
    private static let cachedCurrentGroupKey = "cached_current_group"

    private func cacheGroups() {
        if let data = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(data, forKey: Self.cachedGroupsKey)
        }
        if let group = currentGroup, let data = try? JSONEncoder().encode(group) {
            UserDefaults.standard.set(data, forKey: Self.cachedCurrentGroupKey)
        }
    }

    private func loadCachedGroups() {
        if let data = UserDefaults.standard.data(forKey: Self.cachedGroupsKey),
           let cached = try? JSONDecoder().decode([FamilyGroupBrief].self, from: data) {
            groups = cached
        }
        if let data = UserDefaults.standard.data(forKey: Self.cachedCurrentGroupKey),
           let cached = try? JSONDecoder().decode(FamilyGroup.self, from: data) {
            currentGroup = cached
        }
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
                if groups.contains(where: { $0.id == id }) {
                    currentGroup = try await api.request("\(APIClient.apiBase)/groups/\(id)/")
                } else {
                    currentGroup = groups.isEmpty ? nil : try await api.request("\(APIClient.apiBase)/groups/\(groups[0].id)/")
                }
            } else if let first = groups.first {
                currentGroup = try await api.request("\(APIClient.apiBase)/groups/\(first.id)/")
            }
            await fetchCategories()
            appendLocalLists()
            cacheGroups()
        } catch {
            if !(error is CancellationError) {
                if groups.isEmpty { loadCachedGroups() }
                appendLocalLists()
            }
        }
    }

    private func appendLocalLists() {
        guard let groupId = currentGroup?.id else { return }
        let localLists = (try? store.localLists(forGroup: groupId)) ?? []
        for localList in localLists where localList.apiId == nil {
            let brief = localList.toShoppingListBrief()
            if currentGroup?.lists.contains(where: { $0.id == brief.id }) == false {
                currentGroup?.lists.append(brief)
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
            appendLocalLists()
        } catch {
            let localList = LocalList(name: name, groupApiId: groupId)
            store.context.insert(localList)
            store.save()
            currentGroup?.lists.append(localList.toShoppingListBrief())
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

    func kickMember(groupId: Int, userId: Int) async {
        do {
            try await api.requestVoid(
                "\(APIClient.apiBase)/groups/\(groupId)/kick/",
                method: "POST",
                body: ["user_id": userId]
            )
            currentGroup?.members.removeAll { $0.id == userId }
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
