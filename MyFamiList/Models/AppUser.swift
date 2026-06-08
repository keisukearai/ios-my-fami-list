import Foundation

struct AppUser: Codable, Identifiable {
    let id: Int
    let uid: String
    let provider: String
    var displayName: String
    var avatarEmoji: String
    var deviceToken: String?
}
