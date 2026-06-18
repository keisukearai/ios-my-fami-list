import XCTest
@testable import MyFamiList

@MainActor
final class ItemViewModelSyncTests: XCTestCase {

    private var store: LocalDataStore!

    override func setUp() async throws {
        store = LocalDataStore(inMemory: true)
    }

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func makeVM(mock: SyncAPIClient, listId: Int = 10) -> ItemViewModel {
        ItemViewModel(groupId: 1, listId: listId, api: mock, store: store)
    }

    private func insertPendingDelete(apiId: Int, apiListId: Int) -> LocalItem {
        let item = LocalItem(name: "削除対象", category: "", groupApiId: 1, apiListId: apiListId)
        item.apiId = apiId
        item.isDeleted = true
        store.context.insert(item)
        store.save()
        return item
    }

    private func insertPendingToggle(apiId: Int, apiListId: Int, isChecked: Bool = true) -> LocalItem {
        let item = LocalItem(name: "チェック対象", category: "", groupApiId: 1, apiListId: apiListId)
        item.apiId = apiId
        item.isChecked = isChecked
        // isSynced=false, isDeleted=false → pendingToggles
        store.context.insert(item)
        store.save()
        return item
    }

    private func insertUnsyncedItem(apiListId: Int) -> LocalItem {
        // apiId=nil, isSynced=false, isDeleted=false → unsyncedItems
        let item = LocalItem(name: "新規アイテム", category: "", groupApiId: 1, apiListId: apiListId)
        store.context.insert(item)
        store.save()
        return item
    }

    // MARK: - syncPendingDeletes

    func test_syncPendingDeletes_removes_item_from_store_on_success() async throws {
        let mock = SyncAPIClient()
        let vm = makeVM(mock: mock)
        _ = insertPendingDelete(apiId: 5, apiListId: 10)

        XCTAssertEqual(try store.pendingDeletes().count, 1)
        await vm.syncPending()
        XCTAssertEqual(try store.pendingDeletes().count, 0)
    }

    func test_syncPendingDeletes_retains_item_when_api_fails() async throws {
        let mock = SyncAPIClient()
        mock.shouldFailVoid = true
        let vm = makeVM(mock: mock)
        _ = insertPendingDelete(apiId: 5, apiListId: 10)

        await vm.syncPending()
        XCTAssertEqual(try store.pendingDeletes().count, 1)
    }

    func test_syncPendingDeletes_skips_item_belonging_to_different_list() async throws {
        let mock = SyncAPIClient()
        let vm = makeVM(mock: mock, listId: 10)
        _ = insertPendingDelete(apiId: 5, apiListId: 99) // 別リスト

        await vm.syncPending()
        XCTAssertEqual(try store.pendingDeletes().count, 1)
    }

    func test_syncPendingDeletes_processes_only_matching_list() async throws {
        let mock = SyncAPIClient()
        let vm = makeVM(mock: mock, listId: 10)
        _ = insertPendingDelete(apiId: 1, apiListId: 10) // 対象
        _ = insertPendingDelete(apiId: 2, apiListId: 99) // 別リスト → スキップ

        await vm.syncPending()
        XCTAssertEqual(try store.pendingDeletes().count, 1)
    }

    // MARK: - syncPendingToggles

    func test_syncPendingToggles_marks_item_synced_on_success() async throws {
        let mock = SyncAPIClient()
        mock.syncedItem = Item(id: 7, name: "商品", quantity: "", category: "",
                               memo: "", isChecked: true, addedByName: "", createdAt: "", updatedAt: "")
        let vm = makeVM(mock: mock)
        _ = insertPendingToggle(apiId: 7, apiListId: 10)

        XCTAssertEqual(try store.pendingToggles().count, 1)
        await vm.syncPending()
        XCTAssertEqual(try store.pendingToggles().count, 0)
    }

    func test_syncPendingToggles_retains_item_when_api_fails() async throws {
        let mock = SyncAPIClient()
        mock.shouldFailRequest = true
        let vm = makeVM(mock: mock)
        _ = insertPendingToggle(apiId: 7, apiListId: 10)

        await vm.syncPending()
        XCTAssertEqual(try store.pendingToggles().count, 1)
    }

    func test_syncPendingToggles_skips_item_for_different_list() async throws {
        let mock = SyncAPIClient()
        let vm = makeVM(mock: mock, listId: 10)
        _ = insertPendingToggle(apiId: 7, apiListId: 55)

        await vm.syncPending()
        XCTAssertEqual(try store.pendingToggles().count, 1)
    }

    // MARK: - syncUnsyncedItems

    func test_syncUnsyncedItems_assigns_apiId_from_server_response() async throws {
        let mock = SyncAPIClient()
        mock.syncedItem = Item(id: 100, name: "牛乳", quantity: "", category: "",
                               memo: "", isChecked: false, addedByName: "", createdAt: "", updatedAt: "")
        let vm = makeVM(mock: mock)
        let local = insertUnsyncedItem(apiListId: 10)

        await vm.syncPending()

        XCTAssertEqual(local.apiId, 100)
    }

    func test_syncUnsyncedItems_marks_item_synced_on_success() async throws {
        let mock = SyncAPIClient()
        mock.syncedItem = Item(id: 200, name: "卵", quantity: "", category: "",
                               memo: "", isChecked: false, addedByName: "", createdAt: "", updatedAt: "")
        let vm = makeVM(mock: mock)
        let local = insertUnsyncedItem(apiListId: 10)

        await vm.syncPending()

        XCTAssertTrue(local.isSynced)
        XCTAssertEqual(try store.unsyncedItems(apiListId: 10).count, 0)
    }

    func test_syncUnsyncedItems_retains_item_when_api_fails() async throws {
        let mock = SyncAPIClient()
        mock.shouldFailRequest = true
        let vm = makeVM(mock: mock)
        _ = insertUnsyncedItem(apiListId: 10)

        await vm.syncPending()

        XCTAssertEqual(try store.unsyncedItems(apiListId: 10).count, 1)
    }
}

// MARK: - SyncAPIClient

private class SyncAPIClient: APIClient {
    var shouldFailVoid = false
    var shouldFailRequest = false
    var syncedItem: Item?

    override func request<T: Decodable>(
        _ path: String, method: String = "GET", body: [String: Any]? = nil, retry: Bool = true
    ) async throws -> T {
        if shouldFailRequest { throw APIError.httpError(500, "Server Error") }
        let item = syncedItem ?? Item(id: 999, name: "synced", quantity: "", category: "",
                                     memo: "", isChecked: false, addedByName: "", createdAt: "", updatedAt: "")
        if let result = item as? T { return result }
        if let arr = [Item]() as? T { return arr }
        throw APIError.invalidURL
    }

    override func requestVoid(
        _ path: String, method: String, body: [String: Any]? = nil, retry: Bool = true
    ) async throws {
        if shouldFailVoid { throw APIError.httpError(500, "Server Error") }
    }

    override func saveTokens(access: String, refresh: String) {}
    override func clearTokens() {}
}
