import Foundation
import StoreKit

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable, Sendable {
    case free
    case standard
    case pro

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .standard: return "Standard"
        case .pro: return "Pro"
        }
    }

    var monthlyCredits: Int {
        switch self {
        case .free: return 100 // TODO: change back to 3 for production
        case .standard: return 15
        case .pro: return 50
        }
    }

    var maxSavedWidgets: Int {
        switch self {
        case .free: return 3
        case .standard: return .max
        case .pro: return .max
        }
    }
}

// MARK: - Store Manager

@MainActor @Observable
final class StoreManager {
    var products: [Product] = []
    var purchasedSubscriptions: [Product] = []
    var currentTier: SubscriptionTier = .free
    var isLoading = false
    var errorMessage: String?

    private static let productIDs: Set<String> = [
        "com.lewlian.Widgy.standard",
        "com.lewlian.Widgy.pro"
    ]

    @ObservationIgnored private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedSubscriptions()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: Self.productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedSubscriptions()

        case .userCancelled:
            break

        case .pending:
            errorMessage = "Purchase is pending approval."

        @unknown default:
            errorMessage = "Unknown purchase result."
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        try? await AppStore.sync()
        await updatePurchasedSubscriptions()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    await self?.updatePurchasedSubscriptions()
                }
            }
        }
    }

    // MARK: - Update Subscription Status

    private func updatePurchasedSubscriptions() async {
        var purchased: [Product] = []

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }

            if transaction.productType == .autoRenewable,
               let product = products.first(where: { $0.id == transaction.productID }) {
                purchased.append(product)
            }
        }

        purchasedSubscriptions = purchased

        // Determine current tier
        if purchased.contains(where: { $0.id == "com.lewlian.Widgy.pro" }) {
            currentTier = .pro
        } else if purchased.contains(where: { $0.id == "com.lewlian.Widgy.standard" }) {
            currentTier = .standard
        } else {
            currentTier = .free
        }
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw StoreError.verificationFailed(error.localizedDescription)
        case .verified(let value):
            return value
        }
    }

    func productForTier(_ tier: SubscriptionTier) -> Product? {
        switch tier {
        case .free: return nil
        case .standard: return products.first { $0.id == "com.lewlian.Widgy.standard" }
        case .pro: return products.first { $0.id == "com.lewlian.Widgy.pro" }
        }
    }
}

// MARK: - Store Errors

enum StoreError: Error, LocalizedError {
    case verificationFailed(String)
    case purchaseFailed(String)

    var errorDescription: String? {
        switch self {
        case .verificationFailed(let msg): return "Verification failed: \(msg)"
        case .purchaseFailed(let msg): return "Purchase failed: \(msg)"
        }
    }
}
