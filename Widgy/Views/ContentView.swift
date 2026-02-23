import SwiftUI
import WidgyCore

struct ContentView: View {
    @Environment(ConversationManager.self) private var conversationManager
    @Environment(AuthManager.self) private var authManager
    @Environment(CreditManager.self) private var creditManager
    @State private var selectedTab = 0
    @State private var showingSubscription = false

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                mainContent
            } else {
                SignInView()
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            Tab("Chat", systemImage: "bubble.left.and.text.bubble.right", value: 0) {
                ChatView()
            }

            Tab("Gallery", systemImage: "square.grid.2x2", value: 1) {
                WidgetGalleryView()
            }

            Tab("History", systemImage: "clock.arrow.circlepath", value: 2) {
                ConversationListView()
            }
        }
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

#Preview {
    ContentView()
        .environment(ConversationManager())
        .environment(AuthManager())
        .environment(StoreManager())
        .environment(CreditManager())
}
