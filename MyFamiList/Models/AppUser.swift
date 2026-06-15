import Foundation

struct AppUser: Codable, Identifiable {
    let id: Int
    let uid: String
    let provider: String
    let email: String
    var displayName: String
    var avatarEmoji: String
    var avatarColor: String
    var avatarPhoto: String
    var isPro: Bool

    init(id: Int, uid: String, provider: String, email: String = "",
         displayName: String, avatarEmoji: String, avatarColor: String, avatarPhoto: String, isPro: Bool = false) {
        self.id = id; self.uid = uid; self.provider = provider; self.email = email
        self.displayName = displayName; self.avatarEmoji = avatarEmoji
        self.avatarColor = avatarColor; self.avatarPhoto = avatarPhoto; self.isPro = isPro
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(Int.self, forKey: .id)
        uid          = try c.decode(String.self, forKey: .uid)
        provider     = try c.decode(String.self, forKey: .provider)
        email        = (try? c.decodeIfPresent(String.self, forKey: .email)) ?? ""
        displayName  = try c.decode(String.self, forKey: .displayName)
        avatarEmoji  = try c.decode(String.self, forKey: .avatarEmoji)
        avatarColor  = try c.decode(String.self, forKey: .avatarColor)
        avatarPhoto  = try c.decode(String.self, forKey: .avatarPhoto)
        isPro        = (try? c.decodeIfPresent(Bool.self, forKey: .isPro)) ?? false
    }
}
