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
            "email": "",
            "display_name": "田中太郎",
            "avatar_emoji": "😀",
            "avatar_color": "#16A368",
            "avatar_photo": "",
            "device_token": null
        }
        """.data(using: .utf8)!

        let user = try decoder.decode(AppUser.self, from: json)
        XCTAssertEqual(user.id, 1)
        XCTAssertEqual(user.uid, "apple_uid_12345")
        XCTAssertEqual(user.provider, "apple")
        XCTAssertEqual(user.displayName, "田中太郎")
        XCTAssertEqual(user.avatarEmoji, "😀")
        XCTAssertEqual(user.avatarColor, "#16A368")
    }

    func test_appUser_decodes_with_avatar_photo() throws {
        let json = """
        {
            "id": 2,
            "uid": "google_uid_67890",
            "provider": "google",
            "email": "hanako@example.com",
            "display_name": "佐藤花子",
            "avatar_emoji": "🌸",
            "avatar_color": "#D9695F",
            "avatar_photo": "data:image/jpeg;base64,/9j/abc",
            "device_token": null
        }
        """.data(using: .utf8)!

        let user = try decoder.decode(AppUser.self, from: json)
        XCTAssertEqual(user.provider, "google")
        XCTAssertEqual(user.avatarColor, "#D9695F")
        XCTAssertEqual(user.avatarPhoto, "data:image/jpeg;base64,/9j/abc")
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

    // MARK: - AppUser: email フィールド

    func test_appUser_email_provider_decodes() throws {
        let json = """
        {
            "id": 3,
            "uid": "email_3",
            "provider": "email",
            "email": "user@example.com",
            "display_name": "user",
            "avatar_emoji": "😊",
            "avatar_color": "",
            "avatar_photo": ""
        }
        """.data(using: .utf8)!
        let user = try decoder.decode(AppUser.self, from: json)
        XCTAssertEqual(user.provider, "email")
        XCTAssertEqual(user.email, "user@example.com")
        XCTAssertEqual(user.displayName, "user")
    }

    func test_appUser_missing_email_field_defaults_to_empty() throws {
        let json = """
        {
            "id": 4,
            "uid": "apple_4",
            "provider": "apple",
            "display_name": "旧ユーザー",
            "avatar_emoji": "😊",
            "avatar_color": "",
            "avatar_photo": ""
        }
        """.data(using: .utf8)!
        let user = try decoder.decode(AppUser.self, from: json)
        XCTAssertEqual(user.email, "", "email フィールドがない旧レスポンスは空文字にフォールバック")
    }

    // MARK: - emailLogin / emailRegister

    func test_emailLogin_success_sets_currentUser() async {
        let mock = MockAPIClient()
        let vm = AuthViewModel(api: mock)
        XCTAssertNil(vm.currentUser)

        await vm.emailLogin(email: "user@example.com", password: "password123")

        XCTAssertNotNil(vm.currentUser)
        XCTAssertEqual(vm.currentUser?.provider, "email")
        XCTAssertNil(vm.errorMessage)
    }

    func test_emailLogin_failure_sets_errorMessage() async {
        let mock = MockAPIClient()
        mock.emailLoginResult = .failure(APIError.httpError(401, "メールアドレスまたはパスワードが違います"))
        let vm = AuthViewModel(api: mock)

        await vm.emailLogin(email: "user@example.com", password: "wrong")

        XCTAssertNil(vm.currentUser)
        XCTAssertNotNil(vm.errorMessage)
    }

    func test_emailRegister_success_sets_currentUser() async {
        let mock = MockAPIClient()
        let vm = AuthViewModel(api: mock)

        await vm.emailRegister(email: "new@example.com", password: "password123")

        XCTAssertNotNil(vm.currentUser)
        XCTAssertEqual(vm.currentUser?.email, "new@example.com")
        XCTAssertNil(vm.errorMessage)
    }

    func test_emailRegister_failure_sets_errorMessage() async {
        let mock = MockAPIClient()
        mock.emailRegisterResult = .failure(APIError.httpError(409, "このメールアドレスはすでに登録されています"))
        let vm = AuthViewModel(api: mock)

        await vm.emailRegister(email: "dup@example.com", password: "password123")

        XCTAssertNil(vm.currentUser)
        XCTAssertNotNil(vm.errorMessage)
    }

    func test_emailLogin_clears_previous_errorMessage() async {
        let mock = MockAPIClient()
        let vm = AuthViewModel(api: mock)
        vm.errorMessage = "前回のエラー"

        await vm.emailLogin(email: "user@example.com", password: "password123")

        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - changePassword / requestPasswordReset / confirmPasswordReset

    func test_changePassword_success_does_not_throw() async {
        let mock = MockAPIClient()
        let vm = AuthViewModel(api: mock)
        do {
            try await vm.changePassword(currentPassword: "old", newPassword: "newpass123")
        } catch {
            XCTFail("成功ケースで例外が発生した: \(error)")
        }
    }

    func test_changePassword_failure_throws() async {
        let mock = MockAPIClient()
        mock.passwordChangeError = APIError.httpError(400, "現在のパスワードが違います")
        let vm = AuthViewModel(api: mock)
        do {
            try await vm.changePassword(currentPassword: "wrong", newPassword: "newpass123")
            XCTFail("例外が発生するはず")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func test_requestPasswordReset_success_does_not_throw() async {
        let mock = MockAPIClient()
        let vm = AuthViewModel(api: mock)
        do {
            try await vm.requestPasswordReset(email: "user@example.com")
        } catch {
            XCTFail("成功ケースで例外が発生した: \(error)")
        }
    }

    func test_requestPasswordReset_failure_throws() async {
        let mock = MockAPIClient()
        mock.passwordResetError = APIError.httpError(400, "email is required")
        let vm = AuthViewModel(api: mock)
        do {
            try await vm.requestPasswordReset(email: "")
            XCTFail("例外が発生するはず")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func test_confirmPasswordReset_success_does_not_throw() async {
        let mock = MockAPIClient()
        let vm = AuthViewModel(api: mock)
        do {
            try await vm.confirmPasswordReset(email: "user@example.com", token: "123456", newPassword: "newpass123")
        } catch {
            XCTFail("成功ケースで例外が発生した: \(error)")
        }
    }

    func test_confirmPasswordReset_failure_throws() async {
        let mock = MockAPIClient()
        mock.passwordResetConfirmError = APIError.httpError(400, "コードが無効または期限切れです")
        let vm = AuthViewModel(api: mock)
        do {
            try await vm.confirmPasswordReset(email: "user@example.com", token: "000000", newPassword: "newpass123")
            XCTFail("例外が発生するはず")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Helpers

    private func makeUser(id: Int) -> AppUser {
        AppUser(id: id, uid: "uid_\(id)", provider: "apple", email: "",
                displayName: "テストユーザー", avatarEmoji: "😀",
                avatarColor: "", avatarPhoto: "")
    }
}

// MARK: - MockAPIClient

private class MockAPIClient: APIClient {
    var emailLoginResult: Result<TokenResp, Error> = .success(.init(access: "mock_access", refresh: "mock_refresh"))
    var emailRegisterResult: Result<TokenResp, Error> = .success(.init(access: "mock_access", refresh: "mock_refresh"))
    var passwordResetError: Error? = nil
    var passwordResetConfirmError: Error? = nil
    var passwordChangeError: Error? = nil

    private let mockMe = AppUser(
        id: 1, uid: "email_1", provider: "email", email: "new@example.com",
        displayName: "new", avatarEmoji: "😊", avatarColor: "", avatarPhoto: ""
    )

    override func emailLogin(email: String, password: String) async throws -> TokenResp {
        try emailLoginResult.get()
    }

    override func emailRegister(email: String, password: String) async throws -> TokenResp {
        try emailRegisterResult.get()
    }

    override func requestPasswordReset(email: String) async throws {
        if let e = passwordResetError { throw e }
    }

    override func confirmPasswordReset(email: String, token: String, newPassword: String) async throws {
        if let e = passwordResetConfirmError { throw e }
    }

    override func changePassword(currentPassword: String, newPassword: String) async throws {
        if let e = passwordChangeError { throw e }
    }

    override func request<T: Decodable>(_ path: String, method: String = "GET", body: [String: Any]? = nil, retry: Bool = true) async throws -> T {
        if path.hasSuffix("/auth/me/"), let me = mockMe as? T {
            return me
        }
        throw APIError.invalidURL
    }

    override func saveTokens(access: String, refresh: String) {}
}
