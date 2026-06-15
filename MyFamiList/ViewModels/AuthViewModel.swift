import SwiftUI
import AuthenticationServices
import GoogleSignIn
import CryptoKit

@Observable
@MainActor
final class AuthViewModel: NSObject {
    var currentUser: AppUser?
    var isLoading = false
    var errorMessage: String?

    var isAuthenticated: Bool { currentUser != nil }

    private let api: APIClient
    private var currentNonce: String?

    init(api: APIClient = .shared) {
        self.api = api
        super.init()
    }

    // MARK: - Session

    func checkAuth() async {
        guard api.accessToken != nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let user: AppUser = try await api.request("\(APIClient.apiBase)/auth/me/")
            currentUser = user
            Self.cacheUser(user)
        } catch {
            if let cached = Self.cachedUser() {
                currentUser = cached
            } else {
                api.clearTokens()
            }
        }
    }

    func signOut() {
        api.clearTokens()
        Self.clearCachedUser()
        currentUser = nil
    }

    // MARK: - User cache

    private static let cachedUserKey = "cached_app_user"

    static func cacheUser(_ user: AppUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: cachedUserKey)
        }
    }

    static func cachedUser() -> AppUser? {
        guard let data = UserDefaults.standard.data(forKey: cachedUserKey) else { return nil }
        return try? JSONDecoder().decode(AppUser.self, from: data)
    }

    static func clearCachedUser() {
        UserDefaults.standard.removeObject(forKey: cachedUserKey)
    }

    func deleteAccount() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await api.deleteAccount()
            api.clearTokens()
            currentUser = nil
        } catch {
            errorMessage = error.userFacingMessage
        }
    }

    // MARK: - Apple Sign In

    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Apple Sign In に失敗しました"
                return
            }
            let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            await signIn(provider: "\(APIClient.apiBase)/auth/apple/",
                         body: ["id_token": idToken, "display_name": displayName])

        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.userFacingMessage
            }
        }
    }

    // MARK: - Email Auth

    func emailRegister(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            let resp = try await api.emailRegister(email: email, password: password)
            api.saveTokens(access: resp.access, refresh: resp.refresh)
            currentUser = try await api.request("\(APIClient.apiBase)/auth/me/")
        } catch {
            errorMessage = error.userFacingMessage
        }
    }

    func emailLogin(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            let resp = try await api.emailLogin(email: email, password: password)
            api.saveTokens(access: resp.access, refresh: resp.refresh)
            currentUser = try await api.request("\(APIClient.apiBase)/auth/me/")
        } catch {
            errorMessage = error.userFacingMessage
        }
    }

    func requestPasswordReset(email: String) async throws {
        try await api.requestPasswordReset(email: email)
    }

    func confirmPasswordReset(email: String, token: String, newPassword: String) async throws {
        try await api.confirmPasswordReset(email: email, token: token, newPassword: newPassword)
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        try await api.changePassword(currentPassword: currentPassword, newPassword: newPassword)
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let root = scene.windows.first?.rootViewController
        else { return }

        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google Sign In に失敗しました"
                return
            }
            await signIn(provider: "\(APIClient.apiBase)/auth/google/", body: ["id_token": idToken])
        } catch {
            if (error as? GIDSignInError)?.code != .canceled {
                errorMessage = error.userFacingMessage
            }
        }
    }

    // MARK: - Private

    private func signIn(provider path: String, body: [String: Any]) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        struct TokenResp: Decodable { let access: String; let refresh: String }
        do {
            let resp: TokenResp = try await api.request(path, method: "POST", body: body)
            api.saveTokens(access: resp.access, refresh: resp.refresh)
            currentUser = try await api.request("\(APIClient.apiBase)/auth/me/")
        } catch {
            errorMessage = error.userFacingMessage
        }
    }

    // MARK: - Dev (DEBUG only)

#if DEBUG
    func devLogin() async {
        await signIn(provider: "\(APIClient.apiBase)/auth/dev-login/", body: ["username": "devuser"])
    }
#endif

    private func randomNonceString(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        return String(bytes.map { chars[chars.index(chars.startIndex, offsetBy: Int($0) % chars.count)] })
    }

    private func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
