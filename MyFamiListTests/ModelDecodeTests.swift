import XCTest
@testable import MyFamiList

// MARK: - ShoppingList

final class ShoppingListDecodeTests: XCTestCase {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    func test_decodes_basic_fields() throws {
        let json = """
        {
            "id": 42,
            "name": "週の買い物",
            "items": [],
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-02T00:00:00Z"
        }
        """.data(using: .utf8)!

        let list = try decoder.decode(ShoppingList.self, from: json)
        XCTAssertEqual(list.id, 42)
        XCTAssertEqual(list.name, "週の買い物")
        XCTAssertEqual(list.createdAt, "2026-01-01T00:00:00Z")
        XCTAssertEqual(list.updatedAt, "2026-01-02T00:00:00Z")
    }

    func test_decodes_empty_items_array() throws {
        let json = """
        {"id": 1, "name": "空", "items": [], "created_at": "", "updated_at": ""}
        """.data(using: .utf8)!

        let list = try decoder.decode(ShoppingList.self, from: json)
        XCTAssertTrue(list.items.isEmpty)
    }

    func test_decodes_with_items() throws {
        let json = """
        {
            "id": 1,
            "name": "テスト",
            "items": [
                {
                    "id": 10,
                    "name": "牛乳",
                    "quantity": "1本",
                    "category": "飲料",
                    "memo": "",
                    "is_checked": false,
                    "added_by_name": "太郎",
                    "created_at": "2026-01-01T00:00:00Z",
                    "updated_at": "2026-01-01T00:00:00Z"
                }
            ],
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let list = try decoder.decode(ShoppingList.self, from: json)
        XCTAssertEqual(list.items.count, 1)
        XCTAssertEqual(list.items[0].name, "牛乳")
        XCTAssertEqual(list.items[0].quantity, "1本")
        XCTAssertFalse(list.items[0].isChecked)
    }

    func test_conforms_to_identifiable_via_id() throws {
        let json = """
        {"id": 7, "name": "テスト", "items": [], "created_at": "", "updated_at": ""}
        """.data(using: .utf8)!

        let list = try decoder.decode(ShoppingList.self, from: json)
        XCTAssertEqual(list.id, 7)
    }
}

// MARK: - ListCard 作成日フォーマット

final class ListCardCreatedDateTests: XCTestCase {

    private func formatDate(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = iso.date(from: isoString)
        if date == nil {
            iso.formatOptions = [.withInternetDateTime]
            date = iso.date(from: isoString)
        }
        guard let date else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy/MM/dd"
        return fmt.string(from: date)
    }

    func test_iso8601_formats_to_yyyy_mm_dd() {
        XCTAssertEqual(formatDate("2026-06-28T10:30:00Z"), "2026/06/28")
    }

    func test_iso8601_with_fractional_seconds_formats_correctly() {
        XCTAssertEqual(formatDate("2026-06-28T10:30:00.123456Z"), "2026/06/28")
    }

    func test_different_month_formats_with_zero_padding() {
        XCTAssertEqual(formatDate("2026-01-05T00:00:00Z"), "2026/01/05")
    }

    func test_empty_string_returns_empty() {
        XCTAssertEqual(formatDate(""), "")
    }

    func test_invalid_string_returns_empty() {
        XCTAssertEqual(formatDate("not-a-date"), "")
    }
}

// MARK: - LocalList

@MainActor
final class LocalListModelTests: XCTestCase {

    private var store: LocalDataStore!

    override func setUp() async throws {
        store = LocalDataStore(inMemory: true)
    }

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    func test_init_sets_default_values() {
        let list = LocalList(name: "テストリスト", groupApiId: 1)
        store.context.insert(list)
        store.save()

        XCTAssertNil(list.apiId)
        XCTAssertEqual(list.name, "テストリスト")
        XCTAssertEqual(list.groupApiId, 1)
        XCTAssertFalse(list.isSynced)
        XCTAssertTrue(list.items.isEmpty)
    }

    func test_tempId_is_negative() {
        let list = LocalList(name: "ローカル", groupApiId: 1)
        store.context.insert(list)
        store.save()

        XCTAssertLessThan(list.tempId, 0)
    }

    func test_tempId_is_unique_per_instance() {
        let a = LocalList(name: "A", groupApiId: 1)
        let b = LocalList(name: "B", groupApiId: 1)
        store.context.insert(a)
        store.context.insert(b)
        store.save()

        XCTAssertNotEqual(a.tempId, b.tempId)
    }

    func test_toShoppingListBrief_uses_apiId_when_set() {
        let list = LocalList(name: "テスト", groupApiId: 1)
        list.apiId = 99
        store.context.insert(list)
        store.save()

        XCTAssertEqual(list.toShoppingListBrief().id, 99)
    }

    func test_toShoppingListBrief_uses_tempId_when_apiId_is_nil() {
        let list = LocalList(name: "テスト", groupApiId: 1)
        store.context.insert(list)
        store.save()

        let brief = list.toShoppingListBrief()
        XCTAssertEqual(brief.id, list.tempId)
        XCTAssertLessThan(brief.id, 0)
    }

    func test_toShoppingListBrief_name_matches() {
        let list = LocalList(name: "週の買い物", groupApiId: 5)
        store.context.insert(list)
        store.save()

        XCTAssertEqual(list.toShoppingListBrief().name, "週の買い物")
    }

    func test_toShoppingListBrief_empty_list_has_zero_counts() {
        let list = LocalList(name: "空リスト", groupApiId: 1)
        store.context.insert(list)
        store.save()

        let brief = list.toShoppingListBrief()
        XCTAssertEqual(brief.itemCount, 0)
        XCTAssertEqual(brief.uncheckedCount, 0)
    }
}
