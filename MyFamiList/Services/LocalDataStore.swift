import SwiftData
import Foundation

@MainActor
final class LocalDataStore {
    static let shared = LocalDataStore()
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    private init() {
        self.container = Self.makeContainer(inMemory: false)
    }

    init(inMemory: Bool) {
        self.container = Self.makeContainer(inMemory: inMemory)
    }

    private static func makeContainer(inMemory: Bool) -> ModelContainer {
        let schema = Schema([LocalList.self, LocalItem.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create LocalDataStore: \(error)")
        }
    }

    // MARK: - LocalList

    func unsyncedLists() throws -> [LocalList] {
        let pred = #Predicate<LocalList> { !$0.isSynced }
        return try context.fetch(FetchDescriptor(predicate: pred))
    }

    func localLists(forGroup groupApiId: Int) throws -> [LocalList] {
        let pred = #Predicate<LocalList> { $0.groupApiId == groupApiId }
        return try context.fetch(FetchDescriptor(predicate: pred))
    }

    // MARK: - LocalItem

    func unsyncedItems(apiListId: Int? = nil) throws -> [LocalItem] {
        let pred = #Predicate<LocalItem> { !$0.isSynced && !$0.isDeleted && $0.apiId == nil }
        var descriptor = FetchDescriptor(predicate: pred)
        descriptor.sortBy = [SortDescriptor(\.createdAt)]
        let items = try context.fetch(descriptor)
        if let listId = apiListId {
            return items.filter { $0.apiListId == listId }
        }
        return items
    }

    func pendingDeletes() throws -> [LocalItem] {
        let pred = #Predicate<LocalItem> { !$0.isSynced && $0.isDeleted }
        return try context.fetch(FetchDescriptor(predicate: pred))
    }

    func pendingToggles() throws -> [LocalItem] {
        let pred = #Predicate<LocalItem> { !$0.isSynced && !$0.isDeleted && $0.apiId != nil }
        return try context.fetch(FetchDescriptor(predicate: pred))
    }

    func cachedItems(apiListId: Int) throws -> [LocalItem] {
        let pred = #Predicate<LocalItem> { $0.apiListId == apiListId && !$0.isDeleted }
        return try context.fetch(FetchDescriptor(predicate: pred, sortBy: [SortDescriptor(\.createdAt)]))
    }

    func cachedItems(localListTempId: Int) throws -> [LocalItem] {
        let pred = #Predicate<LocalItem> { $0.localListTempId == localListTempId && !$0.isDeleted }
        return try context.fetch(FetchDescriptor(predicate: pred, sortBy: [SortDescriptor(\.createdAt)]))
    }

    func upsertToggle(apiId: Int, apiListId: Int, groupApiId: Int, item: Item) {
        let pred = #Predicate<LocalItem> { $0.apiId == apiId }
        if let existing = try? context.fetch(FetchDescriptor(predicate: pred)).first {
            existing.isChecked = item.isChecked
            existing.isSynced = false
        } else {
            let local = LocalItem(name: item.name, category: item.category, groupApiId: groupApiId, apiListId: apiListId)
            local.apiId = apiId
            local.quantity = item.quantity
            local.memo = item.memo
            local.isChecked = item.isChecked
            context.insert(local)
        }
        try? context.save()
    }

    func markDeleted(apiId: Int, apiListId: Int, groupApiId: Int, item: Item) {
        let pred = #Predicate<LocalItem> { $0.apiId == apiId }
        if let existing = try? context.fetch(FetchDescriptor(predicate: pred)).first {
            existing.isDeleted = true
            existing.isSynced = false
        } else {
            let local = LocalItem(name: item.name, category: item.category, groupApiId: groupApiId, apiListId: apiListId)
            local.apiId = apiId
            local.isDeleted = true
            context.insert(local)
        }
        try? context.save()
    }

    func save() {
        try? context.save()
    }
}
