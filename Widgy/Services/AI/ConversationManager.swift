import Foundation
import WidgyCore

// MARK: - Conversation Message

struct ConversationMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let widgetConfig: WidgetConfig?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        widgetConfig: WidgetConfig? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.widgetConfig = widgetConfig
        self.timestamp = timestamp
    }

    func toAPIMessage() -> APIMessage {
        APIMessage(role: role.rawValue, content: content)
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

// MARK: - Conversation

struct Conversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [ConversationMessage]
    var currentConfig: WidgetConfig?
    var family: WidgetFamily
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "New Widget",
        messages: [ConversationMessage] = [],
        currentConfig: WidgetConfig? = nil,
        family: WidgetFamily = .systemSmall,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.currentConfig = currentConfig
        self.family = family
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Conversation Manager

@MainActor @Observable
final class ConversationManager {
    var conversations: [Conversation] = []
    var activeConversation: Conversation?

    private let generationService = WidgetGenerationService()

    var isGenerating: Bool { generationService.isGenerating }
    var streamedText: String { generationService.streamedText }

    // MARK: - Conversation Lifecycle

    func startNewConversation(family: WidgetFamily = .systemSmall) -> Conversation {
        let conversation = Conversation(family: family)
        conversations.insert(conversation, at: 0)
        activeConversation = conversation
        return conversation
    }

    func selectConversation(_ conversation: Conversation) {
        activeConversation = conversation
    }

    // MARK: - Send Message

    func sendMessage(_ text: String) async throws -> GenerationResult {
        guard let conversation = activeConversation else {
            let newConvo = startNewConversation()
            activeConversation = newConvo
            return try await sendMessage(text, in: newConvo)
        }

        return try await sendMessage(text, in: conversation)
    }

    private func sendMessage(_ text: String, in conversation: Conversation) async throws -> GenerationResult {
        var conversation = conversation

        // Add user message
        let userMessage = ConversationMessage(role: .user, content: text)
        conversation.messages.append(userMessage)
        conversation.updatedAt = Date()

        // Update title from first message
        if conversation.messages.filter({ $0.role == .user }).count == 1 {
            conversation.title = String(text.prefix(40))
        }

        updateConversation(conversation)

        // Generate widget or get text reply
        let result = try await generationService.generate(
            prompt: text,
            conversationHistory: conversation.messages,
            existingConfig: conversation.currentConfig,
            family: conversation.family
        )

        switch result {
        case .widget(let config):
            let assistantMessage = ConversationMessage(
                role: .assistant,
                content: "Here's your \"\(config.name)\" widget. How would you like to change it?",
                widgetConfig: config
            )
            conversation.messages.append(assistantMessage)
            conversation.currentConfig = config
        case .textReply(let reply):
            let assistantMessage = ConversationMessage(
                role: .assistant,
                content: reply
            )
            conversation.messages.append(assistantMessage)
        }

        conversation.updatedAt = Date()
        updateConversation(conversation)

        return result
    }

    // MARK: - Helpers

    private func updateConversation(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        }
        activeConversation = conversation
    }

    func deleteConversation(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        if activeConversation?.id == id {
            activeConversation = nil
        }
    }
}
