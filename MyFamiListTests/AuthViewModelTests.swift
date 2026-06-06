import XCTest
@testable import MyFamiList

@MainActor
final class AuthViewModelTests: XCTestCase {

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - AppUser Decodable

    func test_appUser_decodes_from_snake_case_json() throws {
        let json = """
        {
            "id": 1,
            "uid": "apple_uid_12345",
            "provider": "apple",
            "display_name": "田中太郎",
            "avatar_emoji": "😀",
            "fcm_token": null
        }
        """.data(using: .utf8)!

        let user = try decoder.decode(AppUser.self, from: json)
        XCTAssertEqual(user.id, 1)
        XCTAssertEqual(user.uid, "apple_uid_12345")
        XCTAssertEqual(user.provider, "apple")
        XCTAssertEqual(user.displayName, "田中太郎")
        XCTAssertEqual(user.avatarEmoji, "😀")
        XCTAssertNil(user.fcmToken)
    }

    func test_appUser_decodes_with_fcm_token() throws {
        let json = """
        {
            "id": 2,
            "uid": "google_uid_67890",
            "provider": "google",
            "display_name": "佐藤花子",
            "avatar_emoji": "🌸",
            "fcm_token": "fcm_token_abc123"
        }
        """.data(using: .utf8)!

        let user = try decoder.decode(AppUser.self, from: json)
        XCTAssertEqual(user.provider, "google")
        XCTAssertEqual(user.fcmToken, "fcm_token_abc123")
    }

    // MARK: - AuthViewModel 初期状態

    func test_authViewModel_initial_state() async {
        let vm = AuthViewModel()
        XCTAssertNil(vm.currentUser)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isAuthenticated)
    }

    // MARK: - isAuthenticated

    func test_isAuthenticated_false_when_no_user() async {
        let vm = AuthViewModel()
        vm.currentUser = nil
        XCTAssertFalse(vm.isAuthenticated)
    }

    func test_isAuthenticated_true_when_user_set() async {
        let vm = AuthViewModel()
        vm.currentUser = makeUser(id: 1)
        XCTAssertTrue(vm.isAuthenticated)
    }

    // MARK: - signOut

    func test_signOut_clears_currentUser() async {
        let vm = AuthViewModel()
        vm.currentUser = makeUser(id: 1)
        XCTAssertTrue(vm.isAuthenticated)

        vm.signOut()

        XCTAssertNil(vm.currentUser)
        XCTAssertFalse(vm.isAuthenticated)
    }

    // MARK: - prepareAppleSignIn

    func test_prepareAppleSignIn_returns_64_char_hex() async {
        let vm = AuthViewModel()
        let hash = vm.prepareAppleSignIn()
        XCTAssertEqual(hash.count, 64)
        XCTAssertTrue(hash.allSatisfy { $0.isHexDigit }, "SHA256 は16進数文字のみで構成される")
    }

    func test_prepareAppleSignIn_returns_different_values_each_call() async {
        let vm = AuthViewModel()
        let hash1 = vm.prepareAppleSignIn()
        let hash2 = vm.prepareAppleSignIn()
        XCTAssertNotEqual(hash1, hash2, "nonce はランダム生成なので毎回異なるはず")
    }

    // MARK: - Helpers

    private func makeUser(id: Int) -> AppUser {
        AppUser(id: id, uid: "uid_\(id)", provider: "apple",
                displayName: "テストユーザー", avatarEmoji: "😀", fcmToken: nil)
    }
}
