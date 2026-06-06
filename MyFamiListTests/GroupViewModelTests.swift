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
                {"id": 10, "display_name": "田中", "avatar_emoji": "😀"},
                {"id": 11, "display_name": "佐藤", "avatar_emoji": "🎉"}
            ],
            "lists": [
                {
                    "id": 100,
                    "name": "週末の買い物",
                    "item_count": 3,
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

    private func makeGroupBrief(id: Int, name: String, isOwner: Bool) -> FamilyGroupBrief {
        FamilyGroupBrief(id: id, name: name, inviteCode: "CODE\(id)", isOwner: isOwner,
                         memberCount: 1, createdAt: "", updatedAt: "")
    }
}
