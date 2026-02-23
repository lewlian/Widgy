import SwiftUI
import WidgyCore

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ConversationMessage

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
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                }
            }

            if message.role == .assistant || message.role == .system {
                Spacer(minLength: 60)
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
                .background(Color.accentColor)
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
