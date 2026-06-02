import Foundation

struct Member: Codable, Identifiable {
    let id: Int
    let displayName: String
    let avatarEmoji: String
}

struct ShoppingListBrief: Codable, Identifiable {
    let id: Int
    var name: String
    let itemCount: Int
    let createdAt: String
    let updatedAt: String
}

struct FamilyGroup: Codable, Identifiable {
    let id: Int
    var name: String
    let inviteCode: String
    let ownerId: Int
    var members: [Member]
    let isOwner: Bool
    var lists: [ShoppingListBrief]
    let createdAt: String
    let updatedAt: String
}

struct FamilyGroupBrief: Codable, Identifiable {
    let id: Int
    var name: String
    let inviteCode: String
    let isOwner: Bool
    let memberCount: Int
    let createdAt: String
    let updatedAt: String
}
