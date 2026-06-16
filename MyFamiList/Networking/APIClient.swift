import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case httpError(Int, String?)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:              return String(localized: "Invalid URL")
        case .unauthorized:            return String(localized: "Authentication required")
        case .httpError(let c, let m): return m ?? "Server error (\(c))"
        case .decodingError(let e):    return "Failed to load data: \(e.localizedDescription)"
        }
    }
}

extension Error {
    var userFacingMessage: String {
        if let api = self as? APIError {
            return api.localizedDescription
        }
        if let url = self as? URLError {
            let code = "(NSURLErrorDomain \(url.code.rawValue))"
            switch url.code {
            case .notConnectedToInternet:  return "\(String(localized: "No internet connection")) \(code)"
            case .cannotConnectToHost:     return "\(String(localized: "Cannot connect to server")) \(code)"
            case .timedOut:                return "\(String(localized: "Connection timed out")) \(code)"
            case .networkConnectionLost:   return "\(String(localized: "Network connection lost")) \(code)"
            case .cannotFindHost:          return "\(String(localized: "Server not found")) \(code)"
            default:                       return "\(String(localized: "Network error")) \(code)"
            }
        }
        return localizedDescription
    }
}

class APIClient {
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

    struct TokenResp: Decodable { let access: String; let refresh: String }

    func emailRegister(email: String, password: String) async throws -> TokenResp {
        try await request("\(Self.apiBase)/auth/register/", method: "POST",
                          body: ["email": email, "password": password])
    }

    func emailLogin(email: String, password: String) async throws -> TokenResp {
        try await request("\(Self.apiBase)/auth/email-login/", method: "POST",
                          body: ["email": email, "password": password])
    }

    func requestPasswordReset(email: String) async throws {
        try await requestVoid("\(Self.apiBase)/auth/password-reset/", method: "POST", body: ["email": email])
    }

    func confirmPasswordReset(email: String, token: String, newPassword: String) async throws {
        try await requestVoid("\(Self.apiBase)/auth/password-reset/confirm/", method: "POST",
                              body: ["email": email, "token": token, "new_password": newPassword])
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        try await requestVoid("\(Self.apiBase)/auth/password-change/", method: "POST",
                              body: ["current_password": currentPassword, "new_password": newPassword])
    }

    func regenerateInviteCode(groupId: Int) async throws -> String {
        struct Resp: Decodable { let inviteCode: String }
        let resp: Resp = try await request("\(Self.apiBase)/groups/\(groupId)/invite/regenerate/", method: "POST")
        return resp.inviteCode
    }

    func deleteAccount() async throws {
        var body: [String: Any] = [:]
        if let token = refreshToken { body["refresh"] = token }
        try await requestVoid("\(Self.apiBase)/auth/delete-account/", method: "DELETE", body: body.isEmpty ? nil : body)
    }

    func activatePro(transactionId: String) async throws -> AppUser {
        return try await request("\(Self.apiBase)/auth/activate-pro/", method: "POST", body: ["transaction_id": transactionId])
    }

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

    func updateProfile(
        displayName: String? = nil,
        avatarEmoji: String? = nil,
        avatarColor: String? = nil,
        avatarPhoto: String? = nil
    ) async throws -> AppUser {
        var body: [String: Any] = [:]
        if let v = displayName  { body["display_name"] = v }
        if let v = avatarEmoji  { body["avatar_emoji"] = v }
        if let v = avatarColor  { body["avatar_color"] = v }
        if let v = avatarPhoto  { body["avatar_photo"] = v }
        return try await request("\(Self.apiBase)/auth/me/", method: "PUT", body: body)
    }

    func updateList(groupId: Int, listId: Int, name: String) async throws -> ShoppingListBrief {
        return try await request(
            "\(Self.apiBase)/groups/\(groupId)/lists/\(listId)/",
            method: "PUT",
            body: ["name": name]
        )
    }

    func fetchCategories(groupId: Int) async throws -> [GroupCategory] {
        return try await request("\(Self.apiBase)/groups/\(groupId)/categories/")
    }

    func createCategory(groupId: Int, name: String, color: String) async throws -> GroupCategory {
        return try await request(
            "\(Self.apiBase)/groups/\(groupId)/categories/",
            method: "POST",
            body: ["name": name, "color": color]
        )
    }

    func updateCategory(groupId: Int, catId: Int, name: String? = nil, color: String? = nil) async throws -> GroupCategory {
        var body: [String: Any] = [:]
        if let n = name  { body["name"] = n }
        if let c = color { body["color"] = c }
        return try await request(
            "\(Self.apiBase)/groups/\(groupId)/categories/\(catId)/",
            method: "PATCH",
            body: body
        )
    }

    func deleteCategory(groupId: Int, catId: Int) async throws {
        try await requestVoid("\(Self.apiBase)/groups/\(groupId)/categories/\(catId)/", method: "DELETE")
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
        req.setValue(LanguageManager.shared.currentLanguage.acceptLanguageHeader, forHTTPHeaderField: "Accept-Language")
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
