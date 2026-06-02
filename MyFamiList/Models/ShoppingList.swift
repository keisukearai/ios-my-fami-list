import Foundation

struct ShoppingList: Codable, Identifiable {
    let id: Int
    var name: String
    var items: [Item]
    let createdAt: String
    let updatedAt: String
}
