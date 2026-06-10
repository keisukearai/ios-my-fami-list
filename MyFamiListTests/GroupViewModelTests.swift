import XCTest
@testable import MyFamiList

@MainActor
final class GroupViewModelTests: XCTestCase {

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - FamilyGroupBrief Decodable

    func test_familyGroupBrief_decodes_from_snake_case_json() throws {
        let json = """
        {
            "id": 1,
            "name": "家族グループ",
            "invite_code": "ABC123",
            "is_owner": true,
            "member_count": 3,
            "list_count": 2,
            "created_at": "2026-06-07T00:00:00Z",
            "updated_at": "2026-06-07T00:00:00Z"
        }
        """.data(using: .utf8)!

        let brief = try decoder.decode(FamilyGroupBrief.self, from: json)
        XCTAssertEqual(brief.id, 1)
        XCTAssertEqual(brief.name, "家族グループ")
        XCTAssertEqual(brief.inviteCode, "ABC123")
        XCTAssertTrue(brief.isOwner)
        XCTAssertEqual(brief.memberCount, 3)
    }

    func test_familyGroupBrief_non_owner() throws {
        let json = """
        {
            "id": 2,
            "name": "友達グループ",
            "invite_code": "XYZ789",
            "is_owner": false,
            "member_count": 5,
            "list_count": 0,
            "created_at": "2026-06-07T00:00:00Z",
            "updated_at": "2026-06-07T00:00:00Z"
        }
        """.data(using: .utf8)!

        let brief = try decoder.decode(FamilyGroupBrief.self, from: json)
        XCTAssertFalse(brief.isOwner)
        XCTAssertEqual(brief.memberCount, 5)
    }

    // MARK: - FamilyGroup Decodable

    func test_familyGroup_decodes_with_members_and_lists() throws {
        let json = """
        {
            "id": 1,
            "name": "家族グループ",
            "invite_code": "ABC123",
            "owner_id": 10,
            "is_owner": true,
            "members": [
                {"id": 10, "display_name": "田中", "avatar_emoji": "😀",
                 "avatar_color": "#16A368", "avatar_photo": ""},
                {"id": 11, "display_name": "佐藤", "avatar_emoji": "🎉",
                 "avatar_color": "", "avatar_photo": ""}
            ],
            "lists": [
                {
                    "id": 100,
                    "name": "週末の買い物",
                    "item_count": 3,
                    "unchecked_count": 2,
                    "categories": ["食品"],
                    "created_at": "2026-06-07T00:00:00Z",
                    "updated_at": "2026-06-07T00:00:00Z"
                }
            ],
            "created_at": "2026-06-07T00:00:00Z",
            "updated_at": "2026-06-07T00:00:00Z"
        }
        """.data(using: .utf8)!

        let group = try decoder.decode(FamilyGroup.self, from: json)
        XCTAssertEqual(group.id, 1)
        XCTAssertEqual(group.ownerId, 10)
        XCTAssertEqual(group.members.count, 2)
        XCTAssertEqual(group.members[0].displayName, "田中")
        XCTAssertEqual(group.members[1].avatarEmoji, "🎉")
        XCTAssertEqual(group.lists.count, 1)
        XCTAssertEqual(group.lists[0].name, "週末の買い物")
        XCTAssertEqual(group.lists[0].itemCount, 3)
    }

    func test_familyGroup_decodes_empty_members_and_lists() throws {
        let json = """
        {
            "id": 1,
            "name": "新グループ",
            "invite_code": "NEW001",
            "owner_id": 1,
            "is_owner": true,
            "members": [],
            "lists": [],
            "created_at": "2026-06-07T00:00:00Z",
            "updated_at": "2026-06-07T00:00:00Z"
        }
        """.data(using: .utf8)!

        let group = try decoder.decode(FamilyGroup.self, from: json)
        XCTAssertTrue(group.members.isEmpty)
        XCTAssertTrue(group.lists.isEmpty)
    }

    // MARK: - GroupViewModel 初期状態

    func test_groupViewModel_initial_state() async {
        let vm = GroupViewModel()
        XCTAssertTrue(vm.groups.isEmpty)
        XCTAssertNil(vm.currentGroup)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func test_groupViewModel_groups_can_be_set_directly() async {
        let vm = GroupViewModel()
        vm.groups = [
            makeGroupBrief(id: 1, name: "グループA", isOwner: true),
            makeGroupBrief(id: 2, name: "グループB", isOwner: false),
        ]
        XCTAssertEqual(vm.groups.count, 2)
        XCTAssertEqual(vm.groups[0].name, "グループA")
        XCTAssertTrue(vm.groups.allSatisfy { $0.id > 0 })
    }

    // MARK: - Helpers

    // MARK: - Member: avatar fields

    func test_member_decodes_avatarColor_and_avatarPhoto() throws {
        let json = """
        {
            "id": 1,
            "display_name": "田中",
            "avatar_emoji": "😀",
            "avatar_color": "#16A368",
            "avatar_photo": "data:image/jpeg;base64,/9j/abc"
        }
        """.data(using: .utf8)!

        let member = try decoder.decode(Member.self, from: json)
        XCTAssertEqual(member.avatarColor, "#16A368")
        XCTAssertEqual(member.avatarPhoto, "data:image/jpeg;base64,/9j/abc")
    }

    func test_member_empty_avatar_fields() throws {
        let json = """
        {
            "id": 2,
            "display_name": "佐藤",
            "avatar_emoji": "",
            "avatar_color": "",
            "avatar_photo": ""
        }
        """.data(using: .utf8)!

        let member = try decoder.decode(Member.self, from: json)
        XCTAssertTrue(member.avatarColor.isEmpty)
        XCTAssertTrue(member.avatarPhoto.isEmpty)
    }

    // MARK: - GroupCategory: decoding

    func test_groupCategory_decodes_from_json() throws {
        let json = """
        {"id": 1, "name": "カスタム", "color": "#FF0000"}
        """.data(using: .utf8)!

        let cat = try decoder.decode(GroupCategory.self, from: json)
        XCTAssertEqual(cat.id, 1)
        XCTAssertEqual(cat.name, "カスタム")
        XCTAssertEqual(cat.color, "#FF0000")
    }

    // MARK: - GroupViewModel: customCategories

    func test_groupViewModel_customCategories_initial_state_is_empty() {
        let vm = GroupViewModel()
        XCTAssertTrue(vm.customCategories.isEmpty)
    }

    func test_groupViewModel_customCategories_can_be_set() {
        let vm = GroupViewModel()
        vm.customCategories = [
            GroupCategory(id: 1, name: "カスタム1", color: "#FF0000"),
            GroupCategory(id: 2, name: "カスタム2", color: "#00FF00"),
        ]
        XCTAssertEqual(vm.customCategories.count, 2)
        XCTAssertEqual(vm.customCategories[0].name, "カスタム1")
        XCTAssertEqual(vm.customCategories[1].color, "#00FF00")
    }

    // MARK: - ListDetailView: allCategories merging

    func test_listDetailView_allCategories_contains_only_defaults_when_no_custom() {
        let view = ListDetailView(
            list: makeListBrief(),
            groupId: 1,
            groupColor: .green,
            customCategories: []
        )
        XCTAssertEqual(view.allCategories.count, AppTheme.categories.count)
        XCTAssertEqual(view.allCategories.map(\.name), AppTheme.categories.map(\.name))
    }

    func test_listDetailView_allCategories_appends_custom_after_defaults() {
        let customs = [
            GroupCategory(id: 1, name: "マイカテゴリ", color: "#FF0000"),
            GroupCategory(id: 2, name: "テストカテゴリ", color: "#0000FF"),
        ]
        let view = ListDetailView(
            list: makeListBrief(),
            groupId: 1,
            groupColor: .green,
            customCategories: customs
        )
        let names = view.allCategories.map(\.name)
        let defaultCount = AppTheme.categories.count
        XCTAssertEqual(view.allCategories.count, defaultCount + 2)
        XCTAssertEqual(Array(names.prefix(defaultCount)), AppTheme.categories.map(\.name))
        XCTAssertTrue(names.contains("マイカテゴリ"))
        XCTAssertTrue(names.contains("テストカテゴリ"))
    }

    func test_itemDetailEditSheet_allCategories_appends_custom() {
        let customs = [GroupCategory(id: 1, name: "カスタム", color: "#123456")]
        let item = Item(id: 1, name: "牛乳", quantity: "", category: "", memo: "",
                        isChecked: false, addedByName: "", createdAt: "", updatedAt: "")
        let itemVM = ItemViewModel(groupId: 1, listId: 1)
        let sheet = ItemDetailEditSheet(
            itemVM: itemVM, item: item, groupColor: .green, customCategories: customs
        )
        XCTAssertEqual(sheet.allCategories.count, AppTheme.categories.count + 1)
        XCTAssertEqual(sheet.allCategories.last?.name, "カスタム")
    }

    // MARK: - Helpers

    private func makeGroupBrief(id: Int, name: String, isOwner: Bool) -> FamilyGroupBrief {
        FamilyGroupBrief(id: id, name: name, inviteCode: "CODE\(id)", isOwner: isOwner,
                         memberCount: 1, listCount: 0, createdAt: "", updatedAt: "")
    }

    private func makeListBrief() -> ShoppingListBrief {
        ShoppingListBrief(id: 1, name: "テストリスト", itemCount: 0, uncheckedCount: 0,
                          categories: [], createdAt: "", updatedAt: "")
    }
}
