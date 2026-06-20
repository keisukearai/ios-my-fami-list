import XCTest
import AuthenticationServices
@testable import MyFamiList

// Apple / Google サインインのうち、SDK コールバックに依存しない
// ロジック部分（nonce 生成・失敗分岐・共通サインインフロー）を検証する。
// ASAuthorization / GIDSignIn の実コールバックは実機専用のため対象外。
@MainActor
final class SignInFlowTests: XCTestCase {

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    // MARK: - prepareAppleSignIn (nonce + SHA256)

    func test_prepareAppleSignIn_returns_64char_hex_sha256() {
        let vm = AuthViewModel(api: SignInMockAPIClient())
        let hashed = vm.prepareAppleSignIn()

        XCTAssertEqual(hashed.count, 64, "SHA256 の 16 進表現は 64 文字")
        XCTAssertTrue(hashed.allSatisfy { $0.isHexDigit }, "16 進文字のみで構成されるはず")
    }

    func test_prepareAppleSignIn_generates_different_nonce_each_call() {
        let vm = AuthViewModel(api: SignInMockAPIClient())
        let a = vm.prepareAppleSignIn()
        let b = vm.prepareAppleSignIn()
        XCTAssertNotEqual(a, b, "nonce はランダムなので毎回異なるハッシュになるはず")
    }

    // MARK: - handleAppleSignIn 失敗分岐

    func test_handleAppleSignIn_cancel_does_not_set_errorMessage() async {
        let vm = AuthViewModel(api: SignInMockAPIClient())
        await vm.handleAppleSignIn(result: .failure(ASAuthorizationError(.canceled)))
        XCTAssertNil(vm.errorMessage, "ユーザーキャンセル時はエラー表示しない")
    }

    func test_handleAppleSignIn_failure_sets_errorMessage() async {
        let vm = AuthViewModel(api: SignInMockAPIClient())
        await vm.handleAppleSignIn(result: .failure(ASAuthorizationError(.failed)))
        XCTAssertNotNil(vm.errorMessage, "キャンセル以外の失敗はエラー表示する")
    }

    // MARK: - 共通サインインフロー（Apple/Google が funnel する signIn(provider:)）
    // devLogin が同じ private signIn(provider:body:) を経由するため、これで共通フローを検証する。

    func test_provider_signIn_success_sets_currentUser_and_fires_pro_callback() async {
        let mock = SignInMockAPIClient()
        mock.proUser = true
        let vm = AuthViewModel(api: mock)

        var proCallbackValue: Bool?
        vm.onProStatusChanged = { proCallbackValue = $0 }

        await vm.devLogin(username: "alice")

        XCTAssertNotNil(vm.currentUser, "サインイン成功で currentUser がセットされる")
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(proCallbackValue, true, "onProStatusChanged にサーバーの is_pro が渡る")
    }

    func test_provider_signIn_failure_sets_errorMessage() async {
        let mock = SignInMockAPIClient()
        mock.failProvider = true
        let vm = AuthViewModel(api: mock)

        await vm.devLogin(username: "alice")

        XCTAssertNil(vm.currentUser)
        XCTAssertNotNil(vm.errorMessage, "サインイン失敗で errorMessage がセットされる")
    }
}

// MARK: - SignInMockAPIClient
//
// プロバイダーのトークン交換エンドポイントと /auth/me/ をモックする。
// signIn(provider:) 内のローカル TokenResp 型は参照できないため、
// JSON を T へデコードする方式で汎用 request<T> を満たす。
private class SignInMockAPIClient: APIClient {
    var failProvider = false
    var proUser = false

    private let snakeDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    override func request<T: Decodable>(_ path: String, method: String = "GET",
                                        body: [String: Any]? = nil, retry: Bool = true) async throws -> T {
        if path.hasSuffix("/auth/me/") {
            let json = """
            {"id":1,"uid":"u1","provider":"apple","email":"",
             "display_name":"A","avatar_emoji":"😀","avatar_color":"","avatar_photo":"",
             "is_pro":\(proUser)}
            """.data(using: .utf8)!
            return try snakeDecoder.decode(T.self, from: json)
        }
        // プロバイダーのトークン交換エンドポイント
        if failProvider { throw APIError.httpError(401, "auth failed") }
        let json = #"{"access":"a","refresh":"r"}"#.data(using: .utf8)!
        return try snakeDecoder.decode(T.self, from: json)
    }

    override func saveTokens(access: String, refresh: String) {}
}
