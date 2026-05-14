import StoreKit
import Combine

// Product IDs — register these in App Store Connect
enum ProductID: String, CaseIterable {
    case fiveLives    = "com.dotrush.lives5"
    case twentyLives  = "com.dotrush.lives20"
    case removeAds    = "com.dotrush.removeads"
    case unlimitedLives = "com.dotrush.unlimited"
}

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    var hasRemovedAds: Bool { purchasedProductIDs.contains(ProductID.removeAds.rawValue) }
    var hasUnlimitedLives: Bool { purchasedProductIDs.contains(ProductID.unlimitedLives.rawValue) }

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
        Task { await refreshPurchasedProducts() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        do {
            let ids = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: ids)
        } catch {
            errorMessage = "Could not load products."
        }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshPurchasedProducts()
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase pending approval."
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    func livesForProduct(_ id: ProductID) -> Int {
        switch id {
        case .fiveLives:    return 5
        case .twentyLives:  return 20
        default:            return 0
        }
    }

    private func refreshPurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let value): return value
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refreshPurchasedProducts()
                }
            }
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
