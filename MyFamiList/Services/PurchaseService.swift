import StoreKit
import Foundation
import Observation

@Observable
class PurchaseService {
    static let productID = "com.keisukearai.myfamilist.premium"

    private(set) var isPro: Bool = false
    private var listenerTask: Task<Void, Never>?

    init() {
        listenerTask = Task {
            await checkCurrentEntitlements()
            await listenForTransactions()
        }
    }

    deinit {
        listenerTask?.cancel()
    }

    func purchase() async throws {
        let products = try await Product.products(for: [Self.productID])
        guard let product = products.first else {
            throw PurchaseError.productNotFound
        }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            isPro = true
            await transaction.finish()
            await syncWithBackend(transactionId: "\(transaction.id)")
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await checkCurrentEntitlements()
    }

    func loadProduct() async -> Product? {
        try? await Product.products(for: [Self.productID]).first
    }

    // サーバー側の is_pro を反映する（別デバイス購入・管理者付与に対応）
    func syncFromServer(isPro: Bool) {
        if isPro && !self.isPro {
            self.isPro = true
        }
    }

    private func checkCurrentEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                isPro = true
                await syncWithBackend(transactionId: "\(transaction.id)")
                return
            }
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                if transaction.productID == Self.productID {
                    isPro = transaction.revocationDate == nil
                    if isPro {
                        await syncWithBackend(transactionId: "\(transaction.id)")
                    }
                }
            }
        }
    }

    private func syncWithBackend(transactionId: String) async {
        if let user = try? await APIClient.shared.activatePro(transactionId: transactionId) {
            await MainActor.run {
                // AuthViewModel が currentUser を保持しているため、isPro 状態は AppUser 側でも更新される
                // ここでは PurchaseService 側の isPro を正とする
                _ = user
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.failedVerification
        case .verified(let value):
            return value
        }
    }

    enum PurchaseError: LocalizedError {
        case productNotFound
        case failedVerification

        var errorDescription: String? {
            switch self {
            case .productNotFound: return loc("Product not found")
            case .failedVerification: return loc("Purchase verification failed")
            }
        }
    }
}
