import SwiftUI
import StoreKit

// MARK: - Subscription View

struct SubscriptionView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(CreditManager.self) private var creditManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Credit balance header
                    creditBalanceCard

                    // Tier cards
                    tierCard(
                        tier: .free,
                        price: "Free",
                        features: [
                            "3 widget generations (one-time)",
                            "All widget sizes",
                            "Basic templates"
                        ]
                    )

                    tierCard(
                        tier: .standard,
                        price: "$4.99/mo",
                        features: [
                            "15 widget generations per month",
                            "All widget sizes",
                            "Priority generation",
                            "Save unlimited widgets"
                        ]
                    )

                    tierCard(
                        tier: .pro,
                        price: "$9.99/mo",
                        features: [
                            "50 widget generations per month",
                            "All widget sizes",
                            "Priority generation",
                            "Save unlimited widgets",
                            "Early access to new features"
                        ]
                    )

                    // Restore purchases
                    Button("Restore Purchases") {
                        Task {
                            await storeManager.restorePurchases()
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Credit Balance Card

    private var creditBalanceCard: some View {
        VStack(spacing: 8) {
            Text("\(creditManager.remainingCredits)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.tint)

            Text("Credits Remaining")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if creditManager.totalCredits > 0 {
                ProgressView(
                    value: Double(creditManager.remainingCredits),
                    total: Double(creditManager.totalCredits)
                )
                .tint(.accentColor)
                .padding(.horizontal, 40)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Tier Card

    private func tierCard(tier: SubscriptionTier, price: String, features: [String]) -> some View {
        let isCurrent = storeManager.currentTier == tier

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.displayName)
                        .font(.title3.bold())

                    Text(price)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isCurrent {
                    Text("Current")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.tint.opacity(0.15))
                        .foregroundStyle(.tint)
                        .clipShape(Capsule())
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)

                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }

            if !isCurrent && tier != .free {
                Button {
                    purchaseTier(tier)
                } label: {
                    Text(storeManager.currentTier == .free ? "Subscribe" : "Upgrade")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            if isCurrent {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.tint, lineWidth: 2)
            }
        }
    }

    // MARK: - Actions

    private func purchaseTier(_ tier: SubscriptionTier) {
        guard let product = storeManager.productForTier(tier) else {
            storeManager.errorMessage = "Product not available."
            return
        }

        Task {
            do {
                try await storeManager.purchase(product)
                creditManager.updateTier(storeManager.currentTier)
            } catch {
                storeManager.errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    SubscriptionView()
        .environment(StoreManager())
        .environment(CreditManager())
}
