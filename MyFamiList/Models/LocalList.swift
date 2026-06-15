import Foundation
import SwiftData

@Model
final class LocalList {
    @Attribute(.unique) var localId: UUID
    var apiId: Int?
    var groupApiId: Int
    var name: String
    var isSynced: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var items: [LocalItem] = []

    init(name: String, groupApiId: Int) {
        self.localId = UUID()
        self.apiId = nil
        self.groupApiId = groupApiId
        self.name = name
        self.isSynced = false
        self.createdAt = Date()
    }

    var tempId: Int { -(abs(localId.hashValue) % 1_000_000_000 + 1) }

    func toShoppingListBrief() -> ShoppingListBrief {
        let dateStr = ISO8601DateFormatter().string(from: createdAt)
        return ShoppingListBrief(
            id: apiId ?? tempId,
            name: name,
            itemCount: items.filter { !$0.isDeleted }.count,
            uncheckedCount: items.filter { !$0.isChecked && !$0.isDeleted }.count,
            categories: [],
            createdAt: dateStr,
            updatedAt: dateStr
        )
    }
}
