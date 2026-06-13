import Foundation

@Observable
final class InviteHandler {
    static let shared = InviteHandler()
    var pendingCode: String?

    func handle(url: URL) -> Bool {
        guard url.host == "ios.kotoragk.com",
              url.pathComponents.count >= 3,
              url.pathComponents[1] == "invite" else { return false }
        pendingCode = url.pathComponents[2].uppercased()
        return true
    }
}
