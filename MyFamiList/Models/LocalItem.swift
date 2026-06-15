import Foundation
import SwiftData

@Model
final class LocalItem {
    @Attribute(.unique) var localId: UUID
    var apiId: Int?          // nil = new item not yet synced
    var apiListId: Int?      // nil = parent list is also local
    var localListTempId: Int? // set when parent list is local
    var groupApiId: Int
    var name: String
    var quantity: String
    var category: String
    var memo: String
    var isChecked: Bool
    var isSynced: Bool
    var isDeleted: Bool
    var createdAt: Date

    var list: LocalList?

    init(name: String, category: String, groupApiId: Int,
         apiListId: Int? = nil, localList: LocalList? = nil) {
        self.localId = UUID()
        self.apiId = nil
        self.apiListId = apiListId
        self.localListTempId = localList?.tempId
        self.groupApiId = groupApiId
        self.name = name
        self.quantity = ""
        self.category = category
        self.memo = ""
        self.isChecked = false
        self.isSynced = false
        self.isDeleted = false
        self.createdAt = Date()
        self.list = localList
    }

    var tempId: Int { -(abs(localId.hashValue) % 1_000_000_000 + 1) }

    func toItem() -> Item {
        let dateStr = ISO8601DateFormatter().string(from: createdAt)
        return Item(
            id: apiId ?? tempId,
            name: name,
            quantity: quantity,
            category: category,
            memo: memo,
            isChecked: isChecked,
            addedByName: "",
            createdAt: dateStr,
            updatedAt: dateStr
        )
    }
}
