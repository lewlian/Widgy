import SwiftUI

/// Reusable credit balance toolbar button that opens the subscription sheet.
struct CreditBadge: ViewModifier {
    @Environment(CreditManager.self) private var creditManager
    @State private var showingSubscription = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSubscription = true
                    } label: {
                        Label("\(creditManager.remainingCredits)", systemImage: "star.circle.fill")
                            .font(.subheadline.bold())
                    }
                }
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
    }
}

extension View {
    func creditBadge() -> some View {
        modifier(CreditBadge())
    }
}
