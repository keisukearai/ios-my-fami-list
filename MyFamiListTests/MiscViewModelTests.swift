import XCTest
@testable import MyFamiList

// MARK: - InviteHandler Tests

final class InviteHandlerTests: XCTestCase {

    func test_handle_valid_invite_url_sets_pendingCode() {
        let handler = InviteHandler()
        let url = URL(string: "https://ios.kotoragk.com/invite/ABC123")!
        let result = handler.handle(url: url)
        XCTAssertTrue(result)
        XCTAssertEqual(handler.pendingCode, "ABC123")
    }

    func test_handle_uppercases_invite_code() {
        let handler = InviteHandler()
        let url = URL(string: "https://ios.kotoragk.com/invite/abc123")!
        _ = handler.handle(url: url)
        XCTAssertEqual(handler.pendingCode, "ABC123")
    }

    func test_handle_wrong_host_returns_false() {
        let handler = InviteHandler()
        let url = URL(string: "https://example.com/invite/ABC123")!
        let result = handler.handle(url: url)
        XCTAssertFalse(result)
        XCTAssertNil(handler.pendingCode)
    }

    func test_handle_wrong_path_returns_false() {
        let handler = InviteHandler()
        let url = URL(string: "https://ios.kotoragk.com/group/ABC123")!
        let result = handler.handle(url: url)
        XCTAssertFalse(result)
        XCTAssertNil(handler.pendingCode)
    }

    func test_handle_missing_code_returns_false() {
        let handler = InviteHandler()
        let url = URL(string: "https://ios.kotoragk.com/invite/")!
        let result = handler.handle(url: url)
        XCTAssertFalse(result)
        XCTAssertNil(handler.pendingCode)
    }
}

// MARK: - LanguageManager Tests

final class LanguageManagerTests: XCTestCase {

    private let manager = LanguageManager()
    private let appleKey = "AppleLanguages"
    private let appKey = LanguageManager.userDefaultsKey

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: appleKey)
        UserDefaults.standard.removeObject(forKey: appKey)
        super.tearDown()
    }

    func test_setLanguage_english_writes_AppleLanguages() {
        manager.setLanguage(.english)
        let langs = UserDefaults.standard.array(forKey: appleKey) as? [String]
        XCTAssertEqual(langs, ["en"])
    }

    func test_setLanguage_japanese_writes_AppleLanguages() {
        manager.setLanguage(.japanese)
        let langs = UserDefaults.standard.array(forKey: appleKey) as? [String]
        XCTAssertEqual(langs, ["ja"])
    }

    func test_setLanguage_system_clears_app_language_key() {
        manager.setLanguage(.english)
        manager.setLanguage(.system)
        // currentLanguage reads from appKey, not appleKey
        XCTAssertEqual(manager.currentLanguage, .system)
    }

    func test_acceptLanguageHeader_english() {
        XCTAssertEqual(AppLanguage.english.acceptLanguageHeader, "en")
    }

    func test_acceptLanguageHeader_japanese() {
        XCTAssertEqual(AppLanguage.japanese.acceptLanguageHeader, "ja")
    }

    func test_currentLanguage_reflects_stored_value() {
        UserDefaults.standard.set("en", forKey: appKey)
        XCTAssertEqual(manager.currentLanguage, .english)
    }

    func test_currentLanguage_defaults_to_system() {
        UserDefaults.standard.removeObject(forKey: appKey)
        XCTAssertEqual(manager.currentLanguage, .system)
    }
}

// MARK: - GroupViewModel Mock Tests

@MainActor
final class GroupViewModelMockTests: XCTestCase {

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    // MARK: - joinGroup

    func test_joinGroup_success_sets_currentGroup() async throws {
        let mock = GroupMockAPIClient()
        let vm = GroupViewModel(api: mock)
        try await vm.joinGroup(inviteCode: "INVITE1")
        XCTAssertNotNil(vm.currentGroup)
        XCTAssertEqual(vm.currentGroup?.name, "モックグループ")
        XCTAssertNil(vm.errorMessage)
    }

    func test_joinGroup_failure_propagates_error() async {
        let mock = GroupMockAPIClient()
        mock.joinGroupError = APIError.httpError(404, "Invalid invite code")
        let vm = GroupViewModel(api: mock)
        do {
            try await vm.joinGroup(inviteCode: "INVALID")
            XCTFail("エラーが投げられるはず")
        } catch {
            XCTAssertNotNil(error)
        }
        XCTAssertNil(vm.currentGroup)
    }

    // MARK: - createGroup failure

    func test_createGroup_failure_propagates_error() async {
        let mock = GroupMockAPIClient()
        mock.createGroupError = APIError.httpError(403, "Pro plan required")
        let vm = GroupViewModel(api: mock)
        do {
            try await vm.createGroup(name: "新グループ")
            XCTFail("エラーが投げられるはず")
        } catch {
            XCTAssertNotNil(error)
        }
        XCTAssertNil(vm.currentGroup)
    }

    // MARK: - selectGroup

    func test_selectGroup_success_sets_currentGroup() async {
        let mock = GroupMockAPIClient()
        let vm = GroupViewModel(api: mock)
        await vm.selectGroup(1)
        XCTAssertNotNil(vm.currentGroup)
        XCTAssertEqual(vm.currentGroup?.id, 1)
        XCTAssertNil(vm.errorMessage)
    }

    func test_selectGroup_failure_sets_errorMessage() async {
        let mock = GroupMockAPIClient()
        mock.selectGroupError = APIError.httpError(404, "Not found")
        let vm = GroupViewModel(api: mock)
        await vm.selectGroup(99)
        XCTAssertNil(vm.currentGroup)
        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: - start / stop

    func test_stop_cancels_polling_task() async {
        let mock = GroupMockAPIClient()
        let vm = GroupViewModel(api: mock)
        vm.start()
        vm.stop()
        XCTAssertNil(vm.currentGroup)
    }
}

// MARK: - ItemViewModel Mock Tests

@MainActor
final class ItemViewModelMockTests: XCTestCase {

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    private func makeItem(id: Int, checked: Bool = false) -> Item {
        Item(id: id, name: "商品\(id)", quantity: "", category: "", memo: "",
             isChecked: checked, addedByName: "", createdAt: "", updatedAt: "")
    }

    // MARK: - clearCheckedItems

    func test_clearCheckedItems_removes_checked_from_items() async {
        let mock = ItemMockAPIClient()
        let vm = ItemViewModel(groupId: 1, listId: 1, api: mock)
        vm.items = [makeItem(id: 1, checked: false), makeItem(id: 2, checked: true), makeItem(id: 3, checked: true)]
        await vm.clearCheckedItems()
        XCTAssertEqual(vm.items.count, 1)
        XCTAssertEqual(vm.items[0].id, 1)
    }

    func test_clearCheckedItems_empty_list_is_noop() async {
        let mock = ItemMockAPIClient()
        let vm = ItemViewModel(groupId: 1, listId: 1, api: mock)
        vm.items = [makeItem(id: 1, checked: false)]
        await vm.clearCheckedItems()
        XCTAssertEqual(vm.items.count, 1)
    }

    // MARK: - updateItem

    func test_updateItem_success_updates_item_in_list() async {
        let mock = ItemMockAPIClient()
        let vm = ItemViewModel(groupId: 1, listId: 1, api: mock)
        let original = makeItem(id: 1)
        vm.items = [original]
        mock.updatedItem = Item(id: 1, name: "変更後", quantity: "2個", category: "野菜",
                                memo: "", isChecked: false, addedByName: "", createdAt: "", updatedAt: "")
        await vm.updateItem(original, name: "変更後", quantity: "2個", category: "野菜", memo: "")
        XCTAssertEqual(vm.items[0].name, "変更後")
        XCTAssertEqual(vm.items[0].quantity, "2個")
        XCTAssertNil(vm.errorMessage)
    }

    func test_updateItem_failure_sets_errorMessage() async {
        let mock = ItemMockAPIClient()
        mock.updateItemError = APIError.httpError(403, "Forbidden")
        let vm = ItemViewModel(groupId: 1, listId: 1, api: mock)
        let item = makeItem(id: 1)
        vm.items = [item]
        await vm.updateItem(item, name: "変更後", quantity: "", category: "", memo: "")
        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: - stop

    func test_stop_cancels_polling() async {
        let mock = ItemMockAPIClient()
        let vm = ItemViewModel(groupId: 1, listId: 1, api: mock)
        vm.stop()
        XCTAssertTrue(vm.items.isEmpty)
    }

    // MARK: - addItem online

    func test_addItem_online_success_appends_to_items() async {
        let mock = ItemMockAPIClient()
        mock.addedItem = makeItem(id: 10)
        let vm = ItemViewModel(groupId: 1, listId: 1, api: mock)
        await vm.addItem(name: "追加テスト", category: "野菜")
        XCTAssertTrue(vm.items.contains { $0.id == 10 })
    }

    func test_addItem_online_failure_falls_back_to_local() async {
        let mock = ItemMockAPIClient()
        mock.addItemError = APIError.httpError(500, "Server Error")
        let vm = ItemViewModel(groupId: 1, listId: 1, api: mock)
        await vm.addItem(name: "ローカル追加", category: "")
        XCTAssertFalse(vm.items.isEmpty)
        XCTAssertTrue(vm.items[0].id < 0)
    }

    // MARK: - toggleCheck online

    func test_toggleCheck_online_updates_checked_state() async {
        let mock = ItemMockAPIClient()
        let item = makeItem(id: 5, checked: false)
        mock.updatedItem = Item(id: 5, name: "商品5", quantity: "", category: "",
                                memo: "", isChecked: true, addedByName: "", createdAt: "", updatedAt: "")
        let vm = ItemViewModel(groupId: 1, listId: 1, api: mock)
        vm.items = [item]
        await vm.toggleCheck(item)
        XCTAssertTrue(vm.items.first { $0.id == 5 }?.isChecked == true)
    }

    // MARK: - deleteItem online

    func test_deleteItem_online_removes_from_items() async {
        let mock = ItemMockAPIClient()
        let item = makeItem(id: 7)
        let vm = ItemViewModel(groupId: 1, listId: 1, api: mock)
        vm.items = [item]
        await vm.deleteItem(item)
        XCTAssertTrue(vm.items.isEmpty)
    }
}

// MARK: - GroupMockAPIClient

private class GroupMockAPIClient: APIClient {
    var joinGroupError: Error? = nil
    var createGroupError: Error? = nil
    var selectGroupError: Error? = nil
    var createCategoryError: Error? = nil
    var updateCategoryError: Error? = nil
    var deleteCategoryError: Error? = nil
    var groupsForFetchAll: [FamilyGroupBrief] = []

    private func mockGroup(id: Int = 1) -> FamilyGroup {
        FamilyGroup(id: id, name: "モックグループ", inviteCode: "MOCK01", ownerId: 1,
                    members: [], isOwner: true, lists: [], createdAt: "", updatedAt: "")
    }

    private func mockCategory(id: Int = 1) -> GroupCategory {
        GroupCategory(id: id, name: "カテゴリ\(id)", color: "#FF0000")
    }

    override func request<T: Decodable>(
        _ path: String, method: String = "GET", body: [String: Any]? = nil, retry: Bool = true
    ) async throws -> T {
        if path.hasSuffix("/groups/join/") {
            if let e = joinGroupError { throw e }
            if let g = mockGroup() as? T { return g }
        }
        if path.hasSuffix("/groups/") && method == "POST" {
            if let e = createGroupError { throw e }
            if let g = mockGroup() as? T { return g }
        }
        // グループ一覧（fetchAll）
        if path.hasSuffix("/groups/") && method == "GET" {
            if let arr = groupsForFetchAll as? T { return arr }
            if let arr = [FamilyGroupBrief]() as? T { return arr }
        }
        // グループ詳細 /groups/{id}/
        if path.contains("/groups/") && method == "GET" {
            if let e = selectGroupError { throw e }
            let gid = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                .components(separatedBy: "/").last.flatMap(Int.init) ?? 1
            if let g = mockGroup(id: gid) as? T { return g }
        }
        throw APIError.invalidURL
    }

    override func fetchCategories(groupId: Int) async throws -> [GroupCategory] { [] }

    override func createCategory(groupId: Int, name: String, color: String) async throws -> GroupCategory {
        if let e = createCategoryError { throw e }
        return mockCategory(id: 99)
    }

    override func updateCategory(groupId: Int, catId: Int, name: String? = nil, color: String? = nil) async throws -> GroupCategory {
        if let e = updateCategoryError { throw e }
        return GroupCategory(id: catId, name: name ?? "更新済み", color: color ?? "#00FF00")
    }

    override func deleteCategory(groupId: Int, catId: Int) async throws {
        if let e = deleteCategoryError { throw e }
    }

    override func saveTokens(access: String, refresh: String) {}
    override func clearTokens() {}
}

// MARK: - ItemMockAPIClient

private class ItemMockAPIClient: APIClient {
    var updatedItem: Item? = nil
    var updateItemError: Error? = nil
    var clearCheckedError: Error? = nil
    var addedItem: Item? = nil
    var addItemError: Error? = nil

    override func request<T: Decodable>(
        _ path: String, method: String = "GET", body: [String: Any]? = nil, retry: Bool = true
    ) async throws -> T {
        if method == "POST" {
            if let e = addItemError { throw e }
            if let item = addedItem as? T { return item }
        }
        if method == "PUT", let e = updateItemError { throw e }
        if method == "PUT", let item = (updatedItem ?? Item(id: 1, name: "商品1", quantity: "", category: "",
                memo: "", isChecked: false, addedByName: "", createdAt: "", updatedAt: "")) as? T {
            return item
        }
        if let arr = [Item]() as? T { return arr }
        throw APIError.invalidURL
    }

    override func requestVoid(_ path: String, method: String, body: [String: Any]? = nil, retry: Bool = true) async throws {
        if let e = clearCheckedError { throw e }
    }

    override func saveTokens(access: String, refresh: String) {}
    override func clearTokens() {}
}

// MARK: - GroupViewModel Category CRUD Tests

final class GroupViewModelCategoryTests: XCTestCase {

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    private func makeVMWithGroup() -> (GroupViewModel, GroupMockAPIClient) {
        let mock = GroupMockAPIClient()
        let vm = GroupViewModel(api: mock)
        vm.currentGroup = FamilyGroup(id: 1, name: "グループ", inviteCode: "ABC123", ownerId: 1,
                                      members: [], isOwner: true, lists: [], createdAt: "", updatedAt: "")
        return (vm, mock)
    }

    func test_createCategory_success_appends_to_customCategories() async throws {
        let (vm, _) = makeVMWithGroup()
        try await vm.createCategory(name: "野菜", color: "#00FF00")
        XCTAssertTrue(vm.customCategories.contains { $0.id == 99 })
    }

    func test_createCategory_failure_throws() async {
        let (vm, mock) = makeVMWithGroup()
        mock.createCategoryError = APIError.httpError(400, "Bad Request")
        do {
            try await vm.createCategory(name: "", color: "")
            XCTFail("例外が発生するはず")
        } catch {
            XCTAssertNotNil(error)
        }
        XCTAssertTrue(vm.customCategories.isEmpty)
    }

    func test_updateCategory_success_updates_customCategories() async throws {
        let (vm, _) = makeVMWithGroup()
        vm.customCategories = [GroupCategory(id: 5, name: "旧名", color: "#FF0000")]
        try await vm.updateCategory(id: 5, name: "新名")
        XCTAssertEqual(vm.customCategories.first?.name, "新名")
    }

    func test_updateCategory_failure_throws() async {
        let (vm, mock) = makeVMWithGroup()
        vm.customCategories = [GroupCategory(id: 5, name: "カテゴリ", color: "#FF0000")]
        mock.updateCategoryError = APIError.httpError(404, "Not Found")
        do {
            try await vm.updateCategory(id: 5, name: "新名")
            XCTFail("例外が発生するはず")
        } catch {
            XCTAssertNotNil(error)
        }
        XCTAssertEqual(vm.customCategories.first?.name, "カテゴリ")
    }

    func test_deleteCategory_success_removes_from_customCategories() async throws {
        let (vm, _) = makeVMWithGroup()
        vm.customCategories = [GroupCategory(id: 3, name: "削除対象", color: "#0000FF")]
        try await vm.deleteCategory(id: 3)
        XCTAssertTrue(vm.customCategories.isEmpty)
    }

    func test_deleteCategory_failure_throws() async {
        let (vm, mock) = makeVMWithGroup()
        vm.customCategories = [GroupCategory(id: 3, name: "削除対象", color: "#0000FF")]
        mock.deleteCategoryError = APIError.httpError(403, "Forbidden")
        do {
            try await vm.deleteCategory(id: 3)
            XCTFail("例外が発生するはず")
        } catch {
            XCTAssertNotNil(error)
        }
        XCTAssertFalse(vm.customCategories.isEmpty)
    }
}

// MARK: - GroupViewModel fetchAll kick detection

final class GroupViewModelKickDetectionTests: XCTestCase {

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    func test_fetchAll_detects_kicked_and_switches_currentGroup() async {
        let mock = GroupMockAPIClient()
        let remaining = FamilyGroupBrief(id: 2, name: "残グループ", inviteCode: "XYZ", isOwner: false, memberCount: 1, listCount: 0, createdAt: "", updatedAt: "")
        mock.groupsForFetchAll = [remaining]
        let vm = GroupViewModel(api: mock)
        vm.currentGroup = FamilyGroup(id: 1, name: "キックされたグループ", inviteCode: "OLD01", ownerId: 99,
                                      members: [], isOwner: false, lists: [], createdAt: "", updatedAt: "")
        await vm.refreshAll()
        XCTAssertNotEqual(vm.currentGroup?.id, 1, "キックされたグループが currentGroup のまま残っている")
    }
}
