import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case httpError(Int, String?)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:             return "URLが不正です"
        case .unauthorized:           return "認証が必要です"
        case .httpError(let c, let m): return m ?? "HTTPエラー \(c)"
        case .decodingError(let e):   return "デコードエラー: \(e.localizedDescription)"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    let baseURL: String
    static let apiBase = "/api/fami_list"
    private let keychain = KeychainHelper.shared

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    init(baseURL: String? = nil) {
        #if targetEnvironment(simulator)
        let defaultURL = "http://localhost:8000"
        #else
        let defaultURL = "https://ios.kotoragk.com"
        #endif
        self.baseURL = baseURL
            ?? ProcessInfo.processInfo.environment["API_BASE_URL"]
            ?? Bundle.main.infoDictionary?["API_BASE_URL"] as? String
            ?? defaultURL
    }

    var accessToken: String?  { keychain.get("access_token") }

    func registerDeviceToken(_ token: String) async {
        try? await requestVoid("\(Self.apiBase)/auth/device-token/", method: "POST", body: ["device_token": token])
    }

    func getNotificationInterval() async throws -> Int {
        struct Resp: Decodable { let notificationInterval: Int }
        let resp: Resp = try await request("\(Self.apiBase)/auth/notification-settings/")
        return resp.notificationInterval
    }

    func updateNotificationInterval(_ interval: Int) async throws {
        try await requestVoid("\(Self.apiBase)/auth/notification-settings/", method: "PATCH", body: ["notification_interval": interval])
    }
    var refreshToken: String? { keychain.get("refresh_token") }

    func saveTokens(access: String, refresh: String) {
        keychain.set("access_token", value: access)
        keychain.set("refresh_token", value: refresh)
    }

    func clearTokens() {
        keychain.delete("access_token")
        keychain.delete("refresh_token")
    }

    // MARK: - Typed request

    @discardableResult
    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        retry: Bool = true
    ) async throws -> T {
        let (data, status) = try await execute(path, method: method, body: body)

        if status == 401 && retry {
            try await refreshAccessToken()
            return try await request(path, method: method, body: body, retry: false)
        }
        try validateStatus(status, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Void request

    func requestVoid(
        _ path: String,
        method: String,
        body: [String: Any]? = nil,
        retry: Bool = true
    ) async throws {
        let (data, status) = try await execute(path, method: method, body: body)

        if status == 401 && retry {
            try await refreshAccessToken()
            try await requestVoid(path, method: method, body: body, retry: false)
            return
        }
        try validateStatus(status, data: data)
    }

    // MARK: - Private

    private func execute(_ path: String, method: String, body: [String: Any]?) async throws -> (Data, Int) {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as! HTTPURLResponse).statusCode
        return (data, status)
    }

    private func validateStatus(_ status: Int, data: Data) throws {
        guard !(200...299).contains(status) else { return }
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let msg = json?["detail"] as? String ?? json?["error"] as? String
        throw APIError.httpError(status, msg)
    }

    private func refreshAccessToken() async throws {
        guard let refresh = refreshToken else { throw APIError.unauthorized }
        struct Resp: Decodable { let access: String }
        let resp: Resp = try await request("\(Self.apiBase)/auth/refresh/", method: "POST", body: ["refresh": refresh], retry: false)
        keychain.set("access_token", value: resp.access)
    }
}
