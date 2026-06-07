import XCTest
@testable import MyFamiList

// Integration tests against VPS API (https://ios.kotoragk.com)
// Requires network access and the test user to exist on VPS.
@MainActor
final class GroupItemIntegrationTests: XCTestCase {

    private static let vpsURL  = "https://ios.kotoragk.com"
    private static let username = "integrationtest"
    private static let password = "IntegrationTest2026!"

    private var api: APIClient!
    private var groupVM: GroupViewModel!
    private var createdGroupId: Int?

    override func setUp() async throws {
        api = APIClient(baseURL: Self.vpsURL)

        struct TokenResp: Decodable { let access: String; let refresh: String }
        let resp: TokenResp = try await api.request(
            "\(APIClient.apiBase)/auth/token/",
            method: "POST",
            body: ["username": Self.username, "password": Self.password]
        )
        api.saveTokens(access: resp.access, refresh: resp.refresh)
        groupVM = GroupViewModel(api: api)
    }

    override func tearDown() async throws {
        if let id = createdGroupId {
            try? await api.requestVoid("\(APIClient.apiBase)/groups/\(id)/", method: "DELETE")
        }
        createdGroupId = nil
        api.clearTokens()
        await Task.yield()
        try await super.tearDown()
    }

    // MARK: - Group

    func test_createGroup_appearsInList() async throws {
        let name = "TestGroup_\(Int(Date().timeIntervalSince1970))"
        try await groupVM.createGroup(name: name)
        createdGroupId = groupVM.currentGroup?.id

        XCTAssertNotNil(groupVM.currentGroup)
        XCTAssertEqual(groupVM.currentGroup?.name, name)
        XCTAssertTrue(groupVM.groups.contains(where: { $0.name == name }))
        XCTAssertNil(groupVM.errorMessage)
    }

    // MARK: - List

    func test_createList_appearsInGroup() async throws {
        let groupName = "TestGroup_\(Int(Date().timeIntervalSince1970))"
        try await groupVM.createGroup(name: groupName)
        createdGroupId = groupVM.currentGroup?.id

        let listName = "TestList_\(Int(Date().timeIntervalSince1970))"
        await groupVM.createList(name: listName)

        XCTAssertTrue(groupVM.currentGroup?.lists.contains(where: { $0.name == listName }) ?? false)
        XCTAssertNil(groupVM.errorMessage)
    }

    func test_deleteList_removesFromGroup() async throws {
        let groupName = "TestGroup_\(Int(Date().timeIntervalSince1970))"
        try await groupVM.createGroup(name: groupName)
        createdGroupId = groupVM.currentGroup?.id

        await groupVM.createList(name: "ToDelete")
        guard let list = groupVM.currentGroup?.lists.first(where: { $0.name == "ToDelete" }) else {
            XCTFail("List not created")
            return
        }

        await groupVM.deleteList(list)
        XCTAssertFalse(groupVM.currentGroup?.lists.contains(where: { $0.id == list.id }) ?? true)
        XCTAssertNil(groupVM.errorMessage)
    }

    // MARK: - Item helpers

    private func makeItemVM(groupId: Int, listId: Int) -> ItemViewModel {
        ItemViewModel(groupId: groupId, listId: listId, api: api)
    }

    private func setupGroupAndList() async throws -> (groupId: Int, listId: Int) {
        let groupName = "TestGroup_\(Int(Date().timeIntervalSince1970))"
        try await groupVM.createGroup(name: groupName)
        guard let group = groupVM.currentGroup else { throw XCTSkip("Group creation failed") }
        createdGroupId = group.id

        let listName = "TestList_\(Int(Date().timeIntervalSince1970))"
        await groupVM.createList(name: listName)
        guard let list = groupVM.currentGroup?.lists.first(where: { $0.name == listName }) else {
            throw XCTSkip("List creation failed")
        }
        return (group.id, list.id)
    }

    // MARK: - Item

    func test_addItem_appearsInList() async throws {
        let (groupId, listId) = try await setupGroupAndList()
        let itemVM = makeItemVM(groupId: groupId, listId: listId)

        await itemVM.addItem(name: "テスト商品", category: "食品")

        XCTAssertTrue(itemVM.items.contains(where: { $0.name == "テスト商品" }))
        XCTAssertNil(itemVM.errorMessage)
    }

    func test_toggleItem_updatesCheckState() async throws {
        let (groupId, listId) = try await setupGroupAndList()
        let itemVM = makeItemVM(groupId: groupId, listId: listId)

        await itemVM.addItem(name: "チェックテスト", category: "食品")
        guard let item = itemVM.items.first(where: { $0.name == "チェックテスト" }) else {
            XCTFail("Item not found")
            return
        }

        XCTAssertFalse(item.isChecked)
        await itemVM.toggleCheck(item)
        XCTAssertTrue(itemVM.items.first(where: { $0.id == item.id })?.isChecked ?? false)
        XCTAssertNil(itemVM.errorMessage)
    }

    func test_deleteItem_removesFromList() async throws {
        let (groupId, listId) = try await setupGroupAndList()
        let itemVM = makeItemVM(groupId: groupId, listId: listId)

        await itemVM.addItem(name: "削除テスト", category: "食品")
        guard let item = itemVM.items.first(where: { $0.name == "削除テスト" }) else {
            XCTFail("Item not found")
            return
        }

        await itemVM.deleteItem(item)
        XCTAssertFalse(itemVM.items.contains(where: { $0.id == item.id }))
        XCTAssertNil(itemVM.errorMessage)
    }

    func test_updateItem_reflectsChanges() async throws {
        let (groupId, listId) = try await setupGroupAndList()
        let itemVM = makeItemVM(groupId: groupId, listId: listId)

        await itemVM.addItem(name: "更新前", category: "食品")
        guard let item = itemVM.items.first(where: { $0.name == "更新前" }) else {
            XCTFail("Item not found")
            return
        }

        await itemVM.updateItem(item, name: "更新後", quantity: "2個", category: "日用品", memo: "メモ")
        let updated = itemVM.items.first(where: { $0.id == item.id })
        XCTAssertEqual(updated?.name, "更新後")
        XCTAssertEqual(updated?.quantity, "2個")
        XCTAssertEqual(updated?.category, "日用品")
        XCTAssertNil(itemVM.errorMessage)
    }
}
