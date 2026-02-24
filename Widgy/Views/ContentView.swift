import SwiftUI
import WidgyCore

struct ContentView: View {
    @Environment(ConversationManager.self) private var conversationManager
    @Environment(AuthManager.self) private var authManager
    @State private var selectedTab = 0

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
        ZStack(alignment: .bottom) {
            // Content area
            Group {
                switch selectedTab {
                case 0: ChatView()
                case 1: WidgetGalleryView()
                case 2: ConversationListView()
                default: ChatView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating tab bar
            floatingTabBar
        }
    }

    // MARK: - Floating Tab Bar

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(icon: "bubble.left.and.text.bubble.right", label: "Chat", tab: 0)
            tabBarItem(icon: "square.grid.2x2", label: "Gallery", tab: 1)
            tabBarItem(icon: "clock.arrow.circlepath", label: "History", tab: 2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.2), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.1), radius: 16, y: 8)
        .padding(.horizontal, 40)
        .padding(.bottom, 4)
    }

    private func tabBarItem(icon: String, label: String, tab: Int) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .symbolVariant(isSelected ? .fill : .none)
                    .symbolRenderingMode(.monochrome)

                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .accentColor.opacity(0.15), radius: 4)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environment(ConversationManager())
        .environment(AuthManager())
        .environment(StoreManager())
        .environment(CreditManager())
}
