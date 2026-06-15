import XCTest
import SwiftData
@testable import MyFamiList

// MARK: - オフラインテスト用モック

private class AlwaysFailAPIClient: APIClient {
    override func request<T: Decodable>(_ path: String, method: String = "GET",
                                        body: [String: Any]? = nil, retry: Bool = true) async throws -> T {
        throw APIError.httpError(503, "Service Unavailable")
    }
    override func requestVoid(_ path: String, method: String,
                              body: [String: Any]? = nil, retry: Bool = true) async throws {
        throw APIError.httpError(503, "Service Unavailable")
    }
    override func saveTokens(access: String, refresh: String) {}
}

// MARK: - LocalList / LocalItem モデルテスト

@MainActor
final class LocalModelTests: XCTestCase {

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    func test_localList_tempId_is_negative() {
        let list = LocalList(name: "テストリスト", groupApiId: 1)
        XCTAssertLessThan(list.tempId, 0)
    }

    func test_localList_tempId_is_stable() {
        let list = LocalList(name: "テストリスト", groupApiId: 1)
        XCTAssertEqual(list.tempId, list.tempId)
    }

    func test_localList_toShoppingListBrief_maps_name() {
        let list = LocalList(name: "週末の買い物", groupApiId: 1)
        let brief = list.toShoppingListBrief()
        XCTAssertEqual(brief.name, "週末の買い物")
        XCTAssertEqual(brief.id, list.tempId)
        XCTAssertEqual(brief.itemCount, 0)
    }

    func test_localList_toShoppingListBrief_uses_apiId_when_synced() {
        let list = LocalList(name: "リスト", groupApiId: 1)
        list.apiId = 42
        let brief = list.toShoppingListBrief()
        XCTAssertEqual(brief.id, 42)
    }

    func test_localItem_tempId_is_negative() {
        let item = LocalItem(name: "牛乳", category: "乳製品", groupApiId: 1, apiListId: 10)
        XCTAssertLessThan(item.tempId, 0)
    }

    func test_localItem_toItem_maps_fields() {
        let item = LocalItem(name: "卵", category: "食品", groupApiId: 1, apiListId: 10)
        item.quantity = "10個"
        item.memo = "メモ"
        item.isChecked = false

        let converted = item.toItem()
        XCTAssertEqual(converted.name, "卵")
        XCTAssertEqual(converted.category, "食品")
        XCTAssertEqual(converted.quantity, "10個")
        XCTAssertEqual(converted.memo, "メモ")
        XCTAssertFalse(converted.isChecked)
        XCTAssertEqual(converted.id, item.tempId)
    }

    func test_localItem_toItem_uses_apiId_when_synced() {
        let item = LocalItem(name: "パン", category: "", groupApiId: 1, apiListId: 10)
        item.apiId = 99
        item.isSynced = true

        let converted = item.toItem()
        XCTAssertEqual(converted.id, 99)
    }

    func test_localItem_defaults() {
        let item = LocalItem(name: "テスト", category: "野菜", groupApiId: 1, apiListId: 5)
        XCTAssertFalse(item.isChecked)
        XCTAssertFalse(item.isSynced)
        XCTAssertFalse(item.isDeleted)
        XCTAssertNil(item.apiId)
        XCTAssertEqual(item.apiListId, 5)
        XCTAssertEqual(item.quantity, "")
        XCTAssertEqual(item.memo, "")
    }
}

// MARK: - AuthViewModel キャッシュテスト

@MainActor
final class AuthViewModelCacheTests: XCTestCase {

    override func setUp() {
        AuthViewModel.clearCachedUser()
    }

    override func tearDown() async throws {
        AuthViewModel.clearCachedUser()
        await Task.yield()
        try await super.tearDown()
    }

    func test_cacheUser_and_retrieve() {
        let user = AppUser(id: 1, uid: "abc", provider: "apple",
                           displayName: "田中", avatarEmoji: "😊", avatarColor: "", avatarPhoto: "")
        AuthViewModel.cacheUser(user)
        let cached = AuthViewModel.cachedUser()
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.id, 1)
        XCTAssertEqual(cached?.displayName, "田中")
        XCTAssertEqual(cached?.provider, "apple")
    }

    func test_clearCachedUser_removes_cache() {
        let user = AppUser(id: 2, uid: "xyz", provider: "google",
                           displayName: "鈴木", avatarEmoji: "🎉", avatarColor: "", avatarPhoto: "")
        AuthViewModel.cacheUser(user)
        AuthViewModel.clearCachedUser()
        XCTAssertNil(AuthViewModel.cachedUser())
    }

    func test_cachedUser_returns_nil_when_empty() {
        XCTAssertNil(AuthViewModel.cachedUser())
    }

    func test_cacheUser_preserves_isPro() {
        let user = AppUser(id: 3, uid: "pro", provider: "email",
                           displayName: "Pro User", avatarEmoji: "👑", avatarColor: "", avatarPhoto: "",
                           isPro: true)
        AuthViewModel.cacheUser(user)
        let cached = AuthViewModel.cachedUser()
        XCTAssertTrue(cached?.isPro == true)
    }
}

// MARK: - GroupViewModel オフラインテスト

@MainActor
final class GroupViewModelOfflineTests: XCTestCase {

    private var store: LocalDataStore!
    private var groupVM: GroupViewModel!
    private var mockAPI: AlwaysFailAPIClient!

    override func setUp() async throws {
        store = LocalDataStore(inMemory: true)
        mockAPI = AlwaysFailAPIClient()
        groupVM = GroupViewModel(api: mockAPI, store: store)
    }

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    func test_createList_offline_adds_to_currentGroup_lists() async {
        groupVM.currentGroup = makeFamilyGroup(id: 1, lists: [])

        await groupVM.createList(name: "オフラインリスト")

        XCTAssertEqual(groupVM.currentGroup?.lists.count, 1)
        XCTAssertEqual(groupVM.currentGroup?.lists.first?.name, "オフラインリスト")
    }

    func test_createList_offline_assigns_negative_id() async {
        groupVM.currentGroup = makeFamilyGroup(id: 1, lists: [])

        await groupVM.createList(name: "ローカルリスト")

        let listId = groupVM.currentGroup?.lists.first?.id ?? 0
        XCTAssertLessThan(listId, 0)
    }

    func test_createList_offline_persists_to_swiftdata() async throws {
        groupVM.currentGroup = makeFamilyGroup(id: 1, lists: [])

        await groupVM.createList(name: "永続化リスト")

        let localLists = try store.localLists(forGroup: 1)
        XCTAssertEqual(localLists.count, 1)
        XCTAssertEqual(localLists.first?.name, "永続化リスト")
        XCTAssertFalse(localLists.first?.isSynced ?? true)
    }

    // MARK: - Helpers

    private func makeFamilyGroup(id: Int, lists: [ShoppingListBrief]) -> FamilyGroup {
        FamilyGroup(id: id, name: "テストグループ", inviteCode: "ABC123",
                    ownerId: 1, members: [], isOwner: true, lists: lists,
                    createdAt: "", updatedAt: "")
    }
}

// MARK: - ItemViewModel オフラインテスト

@MainActor
final class ItemViewModelOfflineTests: XCTestCase {

    private var store: LocalDataStore!
    private var itemVM: ItemViewModel!
    private var mockAPI: AlwaysFailAPIClient!

    override func setUp() async throws {
        store = LocalDataStore(inMemory: true)
        mockAPI = AlwaysFailAPIClient()
        itemVM = ItemViewModel(groupId: 1, listId: 10, api: mockAPI, store: store)
    }

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    func test_addItem_offline_adds_to_items() async {

        await itemVM.addItem(name: "牛乳", category: "乳製品")

        XCTAssertEqual(itemVM.items.count, 1)
        XCTAssertEqual(itemVM.items.first?.name, "牛乳")
    }

    func test_addItem_offline_assigns_negative_id() async {

        await itemVM.addItem(name: "パン", category: "")

        let itemId = itemVM.items.first?.id ?? 0
        XCTAssertLessThan(itemId, 0)
    }

    func test_addItem_offline_persists_to_swiftdata() async throws {

        await itemVM.addItem(name: "卵", category: "食品")

        let localItems = try store.unsyncedItems(apiListId: 10)
        XCTAssertEqual(localItems.count, 1)
        XCTAssertEqual(localItems.first?.name, "卵")
        XCTAssertFalse(localItems.first?.isSynced ?? true)
    }

    func test_deleteItem_offline_removes_from_items() async {
        await itemVM.addItem(name: "削除テスト", category: "")
        let item = itemVM.items.first!

        await itemVM.deleteItem(item)

        XCTAssertTrue(itemVM.items.isEmpty)
    }

    func test_local_list_items_load_from_swiftdata() async throws {
        // listId < 0 のローカルリスト
        let localList = LocalList(name: "ローカル", groupApiId: 1)
        store.context.insert(localList)
        let localItem = LocalItem(name: "ローカルアイテム", category: "", groupApiId: 1, localList: localList)
        store.context.insert(localItem)
        store.save()

        let vm = ItemViewModel(groupId: 1, listId: localList.tempId, api: mockAPI, store: store)
        // fetch を直接呼べないので loadFromStore 相当を start で触れる範囲でテスト
        let cached = try store.cachedItems(localListTempId: localList.tempId)
        XCTAssertEqual(cached.count, 1)
        XCTAssertEqual(cached.first?.name, "ローカルアイテム")
    }
}
