import Foundation

struct AppUser: Codable, Identifiable {
    let id: Int
    let uid: String
    let provider: String
    var displayName: String
    var avatarEmoji: String
    var avatarColor: String
    var avatarPhoto: String
    var deviceToken: String?
}
