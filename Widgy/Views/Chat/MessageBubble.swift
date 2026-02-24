import SwiftUI
import WidgyCore

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ConversationMessage
    @State private var appeared = false
    @State private var widgetAppeared = false

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Text content
                if !message.content.isEmpty {
                    bubbleText
                }

                // Inline widget preview if assistant message has a config
                if let config = message.widgetConfig {
                    WidgetPreviewChrome(config: config)
                        .shadow(color: .accentColor.opacity(widgetAppeared ? 0.25 : 0), radius: 12, y: 2)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                        .scaleEffect(widgetAppeared ? 1 : 0.85)
                        .opacity(widgetAppeared ? 1 : 0)
                        .onAppear {
                            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                                widgetAppeared = true
                            }
                        }
                }
            }

            if message.role == .assistant || message.role == .system {
                Spacer(minLength: 60)
            }
        }
        .offset(y: appeared ? 0 : 12)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private var bubbleText: some View {
        let base = Text(message.content)
            .font(.body)
            .foregroundStyle(message.role == .user ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

        if message.role == .user {
            base
                .background(BrandTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        } else {
            base
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}

#Preview("User Message") {
    MessageBubble(message: ConversationMessage(
        role: .user,
        content: "Create a weather widget with temperature and icon"
    ))
    .padding()
}

#Preview("Assistant Message") {
    MessageBubble(message: ConversationMessage(
        role: .assistant,
        content: "Here's your widget!"
    ))
    .padding()
}
