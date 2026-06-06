import XCTest
@testable import MyFamiList

@MainActor
final class ItemModelTests: XCTestCase {

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - Item Decodable

    func test_item_decodes_from_snake_case_json() throws {
        let json = """
        {
            "id": 1,
            "name": "牛乳",
            "quantity": "2本",
            "category": "乳製品",
            "memo": "",
            "is_checked": false,
            "added_by_name": "田中",
            "created_at": "2026-06-07T00:00:00Z",
            "updated_at": "2026-06-07T00:00:00Z"
        }
        """.data(using: .utf8)!

        let item = try decoder.decode(Item.self, from: json)
        XCTAssertEqual(item.id, 1)
        XCTAssertEqual(item.name, "牛乳")
        XCTAssertEqual(item.quantity, "2本")
        XCTAssertEqual(item.category, "乳製品")
        XCTAssertEqual(item.addedByName, "田中")
        XCTAssertFalse(item.isChecked)
    }

    func test_item_decodes_with_empty_quantity() throws {
        // quantity="" が正しくデコードできる（修正後の確認）
        let json = """
        {
            "id": 2,
            "name": "パン",
            "quantity": "",
            "category": "",
            "memo": "",
            "is_checked": false,
            "added_by_name": "",
            "created_at": "2026-06-07T00:00:00Z",
            "updated_at": "2026-06-07T00:00:00Z"
        }
        """.data(using: .utf8)!

        let item = try decoder.decode(Item.self, from: json)
        XCTAssertEqual(item.quantity, "")
    }

    func test_item_decodes_checked_state() throws {
        let json = """
        {
            "id": 3,
            "name": "卵",
            "quantity": "10個",
            "category": "",
            "memo": "",
            "is_checked": true,
            "added_by_name": "",
            "created_at": "2026-06-07T00:00:00Z",
            "updated_at": "2026-06-07T00:00:00Z"
        }
        """.data(using: .utf8)!

        let item = try decoder.decode(Item.self, from: json)
        XCTAssertTrue(item.isChecked)
    }

    // MARK: - ItemViewModel フィルタリング

    func test_uncheckedItems_excludes_checked() async {
        let vm = ItemViewModel(groupId: 1, listId: 1)
        vm.items = [
            makeItem(id: 1, name: "牛乳", isChecked: false),
            makeItem(id: 2, name: "卵", isChecked: true),
            makeItem(id: 3, name: "パン", isChecked: false),
        ]

        XCTAssertEqual(vm.uncheckedItems.count, 2)
        XCTAssertTrue(vm.uncheckedItems.allSatisfy { !$0.isChecked })
    }

    func test_checkedItems_only_includes_checked() async {
        let vm = ItemViewModel(groupId: 1, listId: 1)
        vm.items = [
            makeItem(id: 1, name: "牛乳", isChecked: false),
            makeItem(id: 2, name: "卵", isChecked: true),
        ]

        XCTAssertEqual(vm.checkedItems.count, 1)
        XCTAssertEqual(vm.checkedItems.first?.name, "卵")
    }

    func test_empty_items_returns_empty_filters() async {
        let vm = ItemViewModel(groupId: 1, listId: 1)
        vm.items = []

        XCTAssertTrue(vm.uncheckedItems.isEmpty)
        XCTAssertTrue(vm.checkedItems.isEmpty)
    }

    // MARK: - Helpers

    private func makeItem(id: Int, name: String, isChecked: Bool) -> Item {
        Item(id: id, name: name, quantity: "", category: "", memo: "",
             isChecked: isChecked, addedByName: "", createdAt: "", updatedAt: "")
    }
}
