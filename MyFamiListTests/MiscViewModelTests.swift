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
}

// MARK: - GroupMockAPIClient

private class GroupMockAPIClient: APIClient {
    var joinGroupError: Error? = nil
    var createGroupError: Error? = nil
    var selectGroupError: Error? = nil

    private func mockGroup(id: Int = 1) -> FamilyGroup {
        FamilyGroup(id: id, name: "モックグループ", inviteCode: "MOCK01", ownerId: 1,
                    members: [], isOwner: true, lists: [], createdAt: "", updatedAt: "")
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
        if path.contains("/groups/") && method == "GET" {
            if let e = selectGroupError { throw e }
            if let g = mockGroup() as? T { return g }
        }
        // fetchAll → groups list
        if let arr = [FamilyGroupBrief]() as? T { return arr }
        throw APIError.invalidURL
    }

    override func saveTokens(access: String, refresh: String) {}
    override func clearTokens() {}
}

// MARK: - ItemMockAPIClient

private class ItemMockAPIClient: APIClient {
    var updatedItem: Item? = nil
    var updateItemError: Error? = nil
    var clearCheckedError: Error? = nil

    override func request<T: Decodable>(
        _ path: String, method: String = "GET", body: [String: Any]? = nil, retry: Bool = true
    ) async throws -> T {
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
