import Foundation

// MARK: - Credit Manager

@MainActor @Observable
final class CreditManager {
    var remainingCredits: Int = 0
    var totalCredits: Int = 0
    var tier: SubscriptionTier = .free

    private static let creditsKey = "com.lewlian.Widgy.remainingCredits"
    private static let tierKey = "com.lewlian.Widgy.creditTier"
    private static let lastResetKey = "com.lewlian.Widgy.lastCreditReset"
    private static let hasUsedFreeCreditsKey = "com.lewlian.Widgy.hasInitializedFreeCredits"

    init() {
        loadCredits()
    }

    // MARK: - Consume Credit

    /// Attempts to consume one credit. Returns true if successful, false if no credits remain.
    func consumeCredit() -> Bool {
        guard remainingCredits > 0 else { return false }
        remainingCredits -= 1
        saveCredits()
        return true
    }

    // MARK: - Update Tier

    /// Called when subscription status changes to update credit allowance.
    func updateTier(_ newTier: SubscriptionTier) {
        let oldTier = tier
        tier = newTier
        totalCredits = newTier.monthlyCredits

        if newTier != oldTier {
            // On tier upgrade, grant the new tier's credits
            if newTier.monthlyCredits > oldTier.monthlyCredits {
                remainingCredits = newTier.monthlyCredits
            }
            saveCredits()
        }

        // Check if monthly reset is needed for paid tiers
        if newTier != .free {
            checkMonthlyReset()
        }
    }

    // MARK: - Monthly Reset

    private func checkMonthlyReset() {
        let now = Date()
        let calendar = Calendar.current

        if let lastReset = UserDefaults.standard.object(forKey: Self.lastResetKey) as? Date {
            // Reset if we're in a new month
            let lastMonth = calendar.component(.month, from: lastReset)
            let currentMonth = calendar.component(.month, from: now)
            let lastYear = calendar.component(.year, from: lastReset)
            let currentYear = calendar.component(.year, from: now)

            if currentMonth != lastMonth || currentYear != lastYear {
                remainingCredits = tier.monthlyCredits
                UserDefaults.standard.set(now, forKey: Self.lastResetKey)
                saveCredits()
            }
        } else {
            // First time — set the reset date
            UserDefaults.standard.set(now, forKey: Self.lastResetKey)
        }
    }

    // MARK: - Persistence

    private func loadCredits() {
        let hasInitialized = UserDefaults.standard.bool(forKey: Self.hasUsedFreeCreditsKey)

        if hasInitialized {
            remainingCredits = UserDefaults.standard.integer(forKey: Self.creditsKey)
        } else {
            // First launch — grant free tier credits (one-time)
            remainingCredits = SubscriptionTier.free.monthlyCredits
            UserDefaults.standard.set(true, forKey: Self.hasUsedFreeCreditsKey)
            saveCredits()
        }

        totalCredits = tier.monthlyCredits
    }

    private func saveCredits() {
        UserDefaults.standard.set(remainingCredits, forKey: Self.creditsKey)
    }
}
