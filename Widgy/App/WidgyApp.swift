import SwiftUI
import WidgyCore

@main
struct WidgyApp: App {
    @State private var conversationManager = ConversationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(conversationManager)
        }
    }
}
