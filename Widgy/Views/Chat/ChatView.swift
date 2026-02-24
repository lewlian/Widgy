import SwiftUI
import WidgyCore

// MARK: - Chat View

struct ChatView: View {
    @Environment(ConversationManager.self) private var conversationManager
    @Environment(CreditManager.self) private var creditManager
    @State private var messageText = ""
    @State private var showingSaveConfirmation = false
    @State private var errorMessage: String?
    @State private var selectedFamily: WidgetFamily = .systemSmall
    @State private var showingSubscription = false

    private let homeScreenFamilies: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Family picker
                familyPicker
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                Divider()

                // Messages
                messagesScrollView

                Divider()

                // Input area
                inputArea
            }
            .navigationTitle("New Widget")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Widget Saved", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your widget has been saved and is ready to use.")
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
        }
    }

    // MARK: - Family Picker

    private var familyPicker: some View {
        Picker("Widget Size", selection: $selectedFamily) {
            ForEach(homeScreenFamilies, id: \.rawValue) { family in
                Text(family.displayName).tag(family)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedFamily) { _, newValue in
            if var conversation = conversationManager.activeConversation {
                conversation.family = newValue
                conversationManager.selectConversation(conversation)
            }
        }
    }

    // MARK: - Messages List

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if messages.isEmpty {
                        emptyState
                    }

                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    // Streaming indicator
                    if conversationManager.isGenerating {
                        streamingIndicator
                            .id("streaming")
                    }

                    // Save button after successful generation
                    if let config = conversationManager.activeConversation?.currentConfig,
                       !conversationManager.isGenerating {
                        saveWidgetButton(config: config)
                            .id("save-button")
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(messages.last?.id, anchor: .bottom)
                }
            }
            .onChange(of: conversationManager.isGenerating) { _, isGenerating in
                if isGenerating {
                    withAnimation {
                        proxy.scrollTo("streaming", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var messages: [ConversationMessage] {
        conversationManager.activeConversation?.messages ?? []
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)

            Image(systemName: "widget.small.badge.plus")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("Describe Your Widget")
                .font(.title2.bold())

            Text("Tell me what you'd like your widget to look like and I'll create it for you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Credit info
            Text("\(creditManager.remainingCredits) credits remaining")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
    }

    // MARK: - Streaming Indicator

    private var streamingIndicator: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Generating widget...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !conversationManager.streamedText.isEmpty {
                    Text(conversationManager.streamedText.prefix(200))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(3)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Spacer(minLength: 60)
        }
    }

    // MARK: - Save Button

    private func saveWidgetButton(config: WidgetConfig) -> some View {
        Button {
            saveWidget(config)
        } label: {
            Label("Save Widget", systemImage: "square.and.arrow.down")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal, 40)
        .padding(.vertical, 8)
    }

    // MARK: - Input Area

    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Describe your widget...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.tint)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || conversationManager.isGenerating)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Check credits before generating
        guard creditManager.consumeCredit() else {
            errorMessage = "No credits remaining. Upgrade your plan to continue creating widgets."
            showingSubscription = true
            return
        }

        messageText = ""

        // Ensure we have an active conversation
        if conversationManager.activeConversation == nil {
            _ = conversationManager.startNewConversation(family: selectedFamily)
        }

        Task {
            do {
                let result = try await conversationManager.sendMessage(text)
                // Refund credit if Claude just replied with text (no widget generated)
                if case .textReply = result {
                    creditManager.remainingCredits += 1
                }
            } catch {
                // Refund credit on failure
                creditManager.remainingCredits += 1
                errorMessage = error.localizedDescription
            }
        }
    }

    private func saveWidget(_ config: WidgetConfig) {
        do {
            var configToSave = config
            configToSave.family = selectedFamily
            try AppGroupManager.shared.saveWidgetConfig(configToSave)
            WidgetReloader.reloadAll()
            showingSaveConfirmation = true
        } catch {
            errorMessage = "Failed to save widget: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ChatView()
        .environment(ConversationManager())
        .environment(CreditManager())
}
