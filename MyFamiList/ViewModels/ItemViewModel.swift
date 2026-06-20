import Foundation
import SwiftData

@Observable
@MainActor
final class ItemViewModel {
    var items: [Item] = []
    var isLoading = false
    var errorMessage: String?

    var uncheckedItems: [Item] { items.filter { !$0.isChecked } }
    var checkedItems: [Item] { items.filter { $0.isChecked } }

    private var pollingTask: Task<Void, Never>?
    private let api: APIClient
    private let groupId: Int
    private let listId: Int
    private let store: LocalDataStore

    private var isLocalList: Bool { listId < 0 }
    private var basePath: String { "\(APIClient.apiBase)/groups/\(groupId)/lists/\(listId)/items/" }

    init(groupId: Int, listId: Int, api: APIClient = .shared, store: LocalDataStore = .shared) {
        self.groupId = groupId
        self.listId = listId
        self.api = api
        self.store = store
    }

    func start() {
        pollingTask?.cancel()
        pollingTask = Task {
            isLoading = true
            if !isLocalList { await syncPending() }
            while !Task.isCancelled {
                await fetch()
                isLoading = false
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func fetch() async {
        if isLocalList {
            loadFromStore()
            return
        }
        do {
            let fetched: [Item] = try await api.request(basePath)
            let localOnly = items.filter { $0.id < 0 }
            items = fetched + localOnly
            store.cacheServerItems(fetched, apiListId: listId, groupApiId: groupId)
        } catch {
            if !(error is CancellationError) && items.isEmpty {
                loadFromStore()
            }
        }
    }

    private func loadFromStore() {
        if isLocalList {
            items = (try? store.cachedItems(localListTempId: listId))?.map { $0.toItem() } ?? []
        } else {
            let local = (try? store.cachedItems(apiListId: listId)) ?? []
            let localItems = local.map { $0.toItem() }
            let existingIds = Set(items.filter { $0.id > 0 }.map { $0.id })
            let newLocal = localItems.filter { !existingIds.contains($0.id) }
            items = items.filter { $0.id > 0 } + newLocal
        }
    }

    // MARK: - CRUD

    func addItem(name: String, category: String) async {
        if isLocalList {
            addItemLocally(name: name, category: category)
            return
        }
        do {
            let newItem: Item = try await api.request(basePath, method: "POST", body: [
                "name": name, "category": category,
                "quantity": "", "memo": "", "is_checked": false
            ] as [String: Any])
            items.append(newItem)
        } catch {
            addItemLocally(name: name, category: category)
        }
    }

    private func addItemLocally(name: String, category: String) {
        let local: LocalItem
        if isLocalList,
           let localList = try? store.localLists(forGroup: groupId).first(where: { $0.tempId == listId }) {
            local = LocalItem(name: name, category: category, groupApiId: groupId, localList: localList)
        } else {
            local = LocalItem(name: name, category: category, groupApiId: groupId, apiListId: listId)
        }
        store.context.insert(local)
        store.save()
        items.append(local.toItem())
    }

    func toggleCheck(_ item: Item) async {
        let newChecked = !item.isChecked
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isChecked = newChecked
        }
        if item.id < 0 {
            if let local = try? store.cachedItems(localListTempId: listId).first(where: { $0.tempId == item.id })
                ?? store.cachedItems(apiListId: listId).first(where: { $0.tempId == item.id }) {
                local.isChecked = newChecked
                store.save()
            }
            return
        }
        do {
            let updated: Item = try await api.request("\(basePath)\(item.id)/", method: "PUT", body: [
                "name": item.name, "quantity": item.quantity,
                "category": item.category, "memo": item.memo,
                "is_checked": newChecked
            ] as [String: Any])
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = updated
            }
        } catch {
            store.upsertToggle(apiId: item.id, apiListId: listId, groupApiId: groupId,
                               item: Item(id: item.id, name: item.name, quantity: item.quantity,
                                          category: item.category, memo: item.memo, isChecked: newChecked,
                                          addedByName: item.addedByName, createdAt: item.createdAt, updatedAt: item.updatedAt))
        }
    }

    func updateItem(_ item: Item, name: String, quantity: String, category: String, memo: String) async {
        guard !isLocalList, item.id > 0 else { return }
        do {
            let updated: Item = try await api.request("\(basePath)\(item.id)/", method: "PUT", body: [
                "name": name, "quantity": quantity,
                "category": category, "memo": memo, "is_checked": item.isChecked
            ] as [String: Any])
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteItem(_ item: Item) async {
        items.removeAll { $0.id == item.id }
        if item.id < 0 {
            let match = (try? store.cachedItems(apiListId: listId))?.first(where: { $0.tempId == item.id })
                ?? (try? store.cachedItems(localListTempId: listId))?.first(where: { $0.tempId == item.id })
            if let local = match {
                store.context.delete(local)
                store.save()
            }
            return
        }
        do {
            try await api.requestVoid("\(basePath)\(item.id)/", method: "DELETE")
        } catch {
            store.markDeleted(apiId: item.id, apiListId: listId, groupApiId: groupId, item: item)
        }
    }

    func clearCheckedItems() async {
        let checked = items.filter { $0.isChecked }
        items.removeAll { $0.isChecked }
        do {
            try await api.requestVoid("\(basePath)bulk_delete/", method: "POST")
        } catch {
            for item in checked where item.id > 0 {
                store.markDeleted(apiId: item.id, apiListId: listId, groupApiId: groupId, item: item)
            }
        }
    }

    // MARK: - Sync pending

    func syncPending() async {
        await syncPendingDeletes()
        await syncPendingToggles()
        await syncUnsyncedItems()
    }

    private func syncPendingDeletes() async {
        guard let pending = try? store.pendingDeletes() else { return }
        for local in pending where local.apiListId == listId {
            guard let apiId = local.apiId else { continue }
            if (try? await api.requestVoid("\(basePath)\(apiId)/", method: "DELETE")) != nil {
                store.context.delete(local)
            }
        }
        store.save()
    }

    private func syncPendingToggles() async {
        guard let pending = try? store.pendingToggles() else { return }
        for local in pending where local.apiListId == listId {
            guard let apiId = local.apiId else { continue }
            if let _: Item = try? await api.request("\(basePath)\(apiId)/", method: "PUT", body: [
                "name": local.name, "quantity": local.quantity,
                "category": local.category, "memo": local.memo,
                "is_checked": local.isChecked
            ] as [String: Any]) {
                local.isSynced = true
            }
        }
        store.save()
    }

    private func syncUnsyncedItems() async {
        guard let pending = try? store.unsyncedItems(apiListId: listId) else { return }
        for local in pending {
            if let synced: Item = try? await api.request(basePath, method: "POST", body: [
                "name": local.name, "category": local.category,
                "quantity": local.quantity, "memo": local.memo,
                "is_checked": local.isChecked
            ] as [String: Any]) {
                local.apiId = synced.id
                local.isSynced = true
                if let idx = items.firstIndex(where: { $0.id == local.tempId }) {
                    items[idx] = synced
                }
            }
        }
        store.save()
    }
}
