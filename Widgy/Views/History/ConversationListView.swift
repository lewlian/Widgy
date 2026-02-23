import SwiftUI
import WidgyCore

// MARK: - Conversation List View

struct ConversationListView: View {
    @Environment(ConversationManager.self) private var conversationManager

    var body: some View {
        NavigationStack {
            Group {
                if conversationManager.conversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            .navigationTitle("History")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No Conversations Yet")
                .font(.title2.bold())

            Text("Your chat history will appear here after you create your first widget.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - List

    private var conversationList: some View {
        List {
            ForEach(conversationManager.conversations) { conversation in
                Button {
                    conversationManager.selectConversation(conversation)
                } label: {
                    conversationRow(conversation)
                }
                .tint(.primary)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let conversation = conversationManager.conversations[index]
                    conversationManager.deleteConversation(conversation.id)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Row

    private func conversationRow(_ conversation: Conversation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(conversation.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(conversation.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let lastMessage = conversation.messages.last {
                Text(lastMessage.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 4) {
                Image(systemName: familyIcon(conversation.family))
                    .font(.caption2)
                Text(conversation.family.displayName)
                    .font(.caption2)

                if conversation.currentConfig != nil {
                    Text("  |  Widget generated")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func familyIcon(_ family: WidgetFamily) -> String {
        switch family {
        case .systemSmall: return "square"
        case .systemMedium: return "rectangle"
        case .systemLarge: return "square.fill"
        default: return "circle"
        }
    }
}

#Preview {
    ConversationListView()
        .environment(ConversationManager())
}
