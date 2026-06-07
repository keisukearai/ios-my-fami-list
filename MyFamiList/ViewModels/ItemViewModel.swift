import Foundation

@Observable
@MainActor
final class ItemViewModel {
    var items: [Item] = []
    var isLoading = false
    var errorMessage: String?

    var uncheckedItems: [Item] { items.filter { !$0.isChecked } }
    var checkedItems: [Item] { items.filter { $0.isChecked } }

    private var pollingTask: Task<Void, Never>?
    private let api: APIClient
    private let groupId: Int
    private let listId: Int

    init(groupId: Int, listId: Int, api: APIClient = .shared) {
        self.groupId = groupId
        self.listId = listId
        self.api = api
    }

    private var basePath: String { "\(APIClient.apiBase)/groups/\(groupId)/lists/\(listId)/items/" }

    func start() {
        pollingTask?.cancel()
        pollingTask = Task {
            isLoading = true
            while !Task.isCancelled {
                await fetch()
                isLoading = false
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func fetch() async {
        do {
            items = try await api.request(basePath)
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }
    }

    func addItem(name: String, category: String) async {
        do {
            let newItem: Item = try await api.request(basePath, method: "POST", body: [
                "name": name,
                "category": category,
                "quantity": "",
                "memo": "",
                "is_checked": false
            ] as [String: Any])
            items.append(newItem)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleCheck(_ item: Item) async {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isChecked.toggle()
        }
        do {
            let updated: Item = try await api.request("\(basePath)\(item.id)/", method: "PUT", body: [
                "name": item.name,
                "quantity": item.quantity,
                "category": item.category,
                "memo": item.memo,
                "is_checked": !item.isChecked
            ] as [String: Any])
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = updated
            }
        } catch {
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx].isChecked = item.isChecked
            }
            errorMessage = error.localizedDescription
        }
    }

    func updateItem(_ item: Item, name: String, quantity: String, category: String, memo: String) async {
        do {
            let updated: Item = try await api.request("\(basePath)\(item.id)/", method: "PUT", body: [
                "name": name,
                "quantity": quantity,
                "category": category,
                "memo": memo,
                "is_checked": item.isChecked
            ] as [String: Any])
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteItem(_ item: Item) async {
        do {
            try await api.requestVoid("\(basePath)\(item.id)/", method: "DELETE")
            items.removeAll { $0.id == item.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearCheckedItems() async {
        do {
            try await api.requestVoid("\(basePath)bulk_delete/", method: "POST")
            items.removeAll { $0.isChecked }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
