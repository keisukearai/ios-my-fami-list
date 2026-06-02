import Foundation

struct Item: Codable, Identifiable {
    let id: Int
    var name: String
    var quantity: String
    var category: String
    var memo: String
    var isChecked: Bool
    let addedByName: String
    let createdAt: String
    let updatedAt: String
}
