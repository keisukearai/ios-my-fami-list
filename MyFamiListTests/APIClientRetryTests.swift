import XCTest
@testable import MyFamiList

// MARK: - URLSession.shared をインターセプトするスタブ
//
// APIClient.execute は URLSession.shared.data(for:) を直接使うため、
// グローバル登録した URLProtocol でレスポンスを差し替えて
// 401 → refresh → retry の実コードパスを検証する。
final class StubURLProtocol: URLProtocol {
    static var refreshCallCount = 0
    static var protectedCallCount = 0
    static var protectedStatusFirst = 401   // 1 回目のステータス
    static var protectedStatusAfter = 200   // 2 回目以降のステータス
    static var protectedPayload = Data()
    static var refreshAccess = "new_access"
    static var refreshRotated = "rotated_refresh"   // ローテーションで返る新 refresh
    static var capturedAuthHeaders: [String] = []

    static func reset() {
        refreshCallCount = 0
        protectedCallCount = 0
        protectedStatusFirst = 401
        protectedStatusAfter = 200
        protectedPayload = Data()
        refreshAccess = "new_access"
        refreshRotated = "rotated_refresh"
        capturedAuthHeaders = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let urlString = request.url?.absoluteString ?? ""
        let status: Int
        let data: Data

        if urlString.contains("/auth/refresh") {
            Self.refreshCallCount += 1
            status = 200
            data = try! JSONSerialization.data(withJSONObject: ["access": Self.refreshAccess, "refresh": Self.refreshRotated])
        } else {
            Self.capturedAuthHeaders.append(request.value(forHTTPHeaderField: "Authorization") ?? "")
            Self.protectedCallCount += 1
            status = Self.protectedCallCount == 1 ? Self.protectedStatusFirst : Self.protectedStatusAfter
            data = Self.protectedPayload
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class APIClientRetryTests: XCTestCase {

    private var api: APIClient!

    private let mePayload = """
    {"id":7,"uid":"u7","provider":"email","email":"a@b.com",
     "display_name":"X","avatar_emoji":"😀","avatar_color":"","avatar_photo":""}
    """.data(using: .utf8)!

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(StubURLProtocol.self)
        StubURLProtocol.reset()
        api = APIClient(baseURL: "https://stub.local")
        api.clearTokens()
    }

    override func tearDown() async throws {
        api.clearTokens()
        URLProtocol.unregisterClass(StubURLProtocol.self)
        StubURLProtocol.reset()
        await Task.yield()
        try await super.tearDown()
    }

    // 401 を受けたら refresh を呼び、新トークンで再試行して成功する
    func test_request_retries_after_401_and_refreshes_token() async throws {
        api.saveTokens(access: "old_access", refresh: "r1")
        StubURLProtocol.protectedPayload = mePayload
        StubURLProtocol.protectedStatusFirst = 401
        StubURLProtocol.protectedStatusAfter = 200

        let user: AppUser = try await api.request("\(APIClient.apiBase)/auth/me/")

        XCTAssertEqual(user.id, 7)
        XCTAssertEqual(StubURLProtocol.refreshCallCount, 1, "401 を受けたら refresh が 1 回呼ばれるはず")
        XCTAssertEqual(StubURLProtocol.protectedCallCount, 2, "元リクエストは合計 2 回（初回 + 再試行）")
        XCTAssertEqual(StubURLProtocol.capturedAuthHeaders.first, "Bearer old_access")
        XCTAssertEqual(StubURLProtocol.capturedAuthHeaders.last, "Bearer new_access",
                       "再試行はリフレッシュ後の新アクセストークンを使うはず")
    }

    // refresh 時にローテーションで返る新 refresh トークンを Keychain に保存する
    // （ROTATE_REFRESH_TOKENS=True + BLACKLIST_AFTER_ROTATION=True 対応）
    func test_refresh_persists_rotated_refresh_token() async throws {
        api.saveTokens(access: "old_access", refresh: "r1")
        StubURLProtocol.protectedPayload = mePayload
        StubURLProtocol.protectedStatusFirst = 401
        StubURLProtocol.protectedStatusAfter = 200
        StubURLProtocol.refreshRotated = "r2"

        let _: AppUser = try await api.request("\(APIClient.apiBase)/auth/me/")

        XCTAssertEqual(api.refreshToken, "r2",
                       "ローテーションで返った新 refresh が保存されないと次回 refresh が失効済みトークンで 401 になる")
    }

    // refresh トークンが無い場合は再試行せず unauthorized を投げる
    func test_request_throws_unauthorized_when_no_refresh_token() async {
        api.clearTokens()  // refresh トークン無し
        StubURLProtocol.protectedStatusFirst = 401

        do {
            let _: AppUser = try await api.request("\(APIClient.apiBase)/auth/me/")
            XCTFail("unauthorized が投げられるはず")
        } catch let error as APIError {
            guard case .unauthorized = error else {
                return XCTFail("APIError.unauthorized を期待したが \(error)")
            }
        } catch {
            XCTFail("APIError を期待したが \(error)")
        }
        XCTAssertEqual(StubURLProtocol.refreshCallCount, 0, "refresh トークンが無いので refresh は呼ばれない")
    }

    // 401 以外の HTTP エラーは再試行せずそのまま伝播する
    func test_request_propagates_non401_http_error_without_retry() async {
        api.saveTokens(access: "old_access", refresh: "r1")
        StubURLProtocol.protectedStatusFirst = 500
        StubURLProtocol.protectedPayload = #"{"detail":"boom"}"#.data(using: .utf8)!

        do {
            let _: AppUser = try await api.request("\(APIClient.apiBase)/auth/me/")
            XCTFail("httpError が投げられるはず")
        } catch let error as APIError {
            guard case .httpError(let code, let msg) = error else {
                return XCTFail("APIError.httpError を期待したが \(error)")
            }
            XCTAssertEqual(code, 500)
            XCTAssertEqual(msg, "boom")
        } catch {
            XCTFail("APIError を期待したが \(error)")
        }
        XCTAssertEqual(StubURLProtocol.refreshCallCount, 0)
        XCTAssertEqual(StubURLProtocol.protectedCallCount, 1, "再試行されないので 1 回のみ")
    }

    // requestVoid（戻り値なし API）でも 401 → refresh → retry が機能する
    func test_requestVoid_retries_after_401() async throws {
        api.saveTokens(access: "old_access", refresh: "r1")
        StubURLProtocol.protectedStatusFirst = 401
        StubURLProtocol.protectedStatusAfter = 200
        StubURLProtocol.protectedPayload = Data()

        try await api.updateNotificationInterval(5)

        XCTAssertEqual(StubURLProtocol.refreshCallCount, 1)
        XCTAssertEqual(StubURLProtocol.protectedCallCount, 2)
    }
}
