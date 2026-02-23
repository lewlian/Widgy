import SwiftUI
import WidgyCore

struct ContentView: View {
    @Environment(ConversationManager.self) private var conversationManager
    @State private var selectedTab = 0

    var body: some View {
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
    }
}

#Preview {
    ContentView()
        .environment(ConversationManager())
}
