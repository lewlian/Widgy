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
                            "Save up to 3 widgets",
                            "All widget sizes"
                        ],
                        gradient: nil
                    )

                    tierCard(
                        tier: .standard,
                        price: "$4.99/mo",
                        features: [
                            "15 widget generations per month",
                            "All widget sizes",
                            "Priority generation",
                            "Save unlimited widgets"
                        ],
                        gradient: LinearGradient(
                            colors: [Color.accentColor.opacity(0.06), Color.accentColor.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
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
                        ],
                        gradient: LinearGradient(
                            colors: [Color(red: 0.44, green: 0.38, blue: 0.99).opacity(0.12), Color(red: 0.33, green: 0.55, blue: 1.0).opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
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
                .contentTransition(.numericText(value: Double(creditManager.remainingCredits)))
                .animation(.spring(duration: 0.4), value: creditManager.remainingCredits)

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

    private func tierCard(tier: SubscriptionTier, price: String, features: [String], gradient: LinearGradient?) -> some View {
        let isCurrent = storeManager.currentTier == tier
        let isPro = tier == .pro

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(tier.displayName)
                            .font(.title3.bold())

                        if isPro {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                        }
                    }

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
                }
                .buttonStyle(.brand)
                .padding(.top, 4)
            }
        }
        .padding()
        .background {
            if let gradient {
                RoundedRectangle(cornerRadius: 16)
                    .fill(gradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            if isCurrent {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.tint, lineWidth: 2)
            } else if isPro {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color(red: 0.44, green: 0.38, blue: 0.99).opacity(0.5), Color(red: 0.33, green: 0.55, blue: 1.0).opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
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
