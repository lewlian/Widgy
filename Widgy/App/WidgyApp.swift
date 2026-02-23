import SwiftUI
import WidgyCore

@main
struct WidgyApp: App {
    @State private var conversationManager = ConversationManager()
    @State private var authManager = AuthManager()
    @State private var storeManager = StoreManager()
    @State private var creditManager = CreditManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(conversationManager)
                .environment(authManager)
                .environment(storeManager)
                .environment(creditManager)
                .onChange(of: storeManager.currentTier) { _, newTier in
                    creditManager.updateTier(newTier)
                }
        }
    }
}
