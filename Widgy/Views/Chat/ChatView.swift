import SwiftUI
import WidgyCore

// MARK: - Chat View

struct ChatView: View {
    @Environment(ConversationManager.self) private var conversationManager
    @Environment(CreditManager.self) private var creditManager
    @Environment(StoreManager.self) private var storeManager
    @State private var messageText = ""
    @State private var showingSaveConfirmation = false
    @State private var errorMessage: String?
    @State private var selectedFamily: WidgetFamily = .systemSmall
    @State private var showingSubscription = false
    @State private var showingSaveLimitAlert = false

    private let homeScreenFamilies: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Family picker
                familyPicker
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                Divider()

                // Messages with floating input overlay
                ZStack(alignment: .bottom) {
                    messagesScrollView

                    // Floating input bar
                    inputArea
                }
            }
            .navigationTitle("New Widget")
            .navigationBarTitleDisplayMode(.inline)
            .creditBadge()
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
            .alert("Widget Limit Reached", isPresented: $showingSaveLimitAlert) {
                Button("Upgrade") { showingSubscription = true }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Free accounts can save up to \(storeManager.currentTier.maxSavedWidgets) widgets. Upgrade to save unlimited widgets.")
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
            .sensoryFeedback(.success, trigger: showingSaveConfirmation)
            .sensoryFeedback(.warning, trigger: showingSaveLimitAlert)
            .sensoryFeedback(.error, trigger: errorMessage) { _, newValue in
                newValue != nil
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
                .padding(.bottom, 70) // Space for floating input bar
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

    // MARK: - Suggestion Chips

    private let suggestions: [(icon: String, text: String, prompt: String)] = [
        ("clock.fill", "Minimal Clock", "A minimal clock widget with the current time in large bold text and the date below in a smaller font, on a dark background"),
        ("cloud.sun.fill", "Weather Dashboard", "A weather widget showing the current temperature in large text, weather condition icon, and today's high/low temperatures"),
        ("battery.75percent", "Battery Meter", "A battery level widget with a circular gauge showing the current percentage, in a clean modern style"),
        ("calendar", "Next Event", "A calendar widget showing my next upcoming event with the event name, time, and a subtle calendar icon"),
        ("figure.run", "Fitness Tracker", "A fitness widget showing today's steps count with a progress ring and a small running icon"),
        ("quote.opening", "Daily Quote", "An inspirational quote widget with elegant serif text centered on a soft gradient background"),
    ]

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 40)

            Image(systemName: "widget.small.badge.plus")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("Describe Your Widget")
                .font(.title2.bold())

            Text("Tell me what you'd like your widget to look like, or try a suggestion below.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Suggestion chips
            suggestionChips

            // Credit info
            Text("\(creditManager.remainingCredits) credits remaining")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
    }

    private var suggestionChips: some View {
        FlowLayout(spacing: 8) {
            ForEach(suggestions, id: \.text) { suggestion in
                Button {
                    messageText = suggestion.prompt
                    sendMessage()
                } label: {
                    Label(suggestion.text, systemImage: suggestion.icon)
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Streaming Indicator

    private var streamingIndicator: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    TypingIndicator()
                    Text("Generating...")
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
        }
        .buttonStyle(.brand)
        .padding(.horizontal, 40)
        .padding(.vertical, 8)
    }

    // MARK: - Input Area

    private var inputArea: some View {
        HStack(spacing: 10) {
            TextField("Describe your widget...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(.leading, 16)
                .padding(.vertical, 10)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || conversationManager.isGenerating
                        ? Color.secondary.opacity(0.4)
                        : Color.accentColor
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || conversationManager.isGenerating)
            .padding(.trailing, 6)
        }
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
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
        // Check save limit for free tier
        let savedCount = (try? AppGroupManager.shared.loadAllWidgetConfigs().count) ?? 0
        let maxAllowed = storeManager.currentTier.maxSavedWidgets
        if savedCount >= maxAllowed {
            showingSaveLimitAlert = true
            return
        }

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
        .environment(StoreManager())
}
