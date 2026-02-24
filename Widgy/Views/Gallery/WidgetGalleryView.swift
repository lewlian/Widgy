import SwiftUI
import WidgyCore

// MARK: - Widget Gallery View

struct WidgetGalleryView: View {
    @Environment(ConversationManager.self) private var conversationManager
    @Environment(StoreManager.self) private var storeManager
    @State private var savedWidgets: [WidgetConfig] = []
    @State private var errorMessage: String?
    @State private var widgetToRename: WidgetConfig?
    @State private var renameText = ""
    @State private var showingRenameAlert = false
    @State private var showingSaveLimitAlert = false
    @State private var showingSubscription = false

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if savedWidgets.isEmpty {
                    emptyState
                } else {
                    widgetGrid
                }
            }
            .navigationTitle("My Widgets")
            .creditBadge()
            .onAppear { loadWidgets() }
            .refreshable { loadWidgets() }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
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
            .alert("Rename Widget", isPresented: $showingRenameAlert) {
                TextField("Widget name", text: $renameText)
                Button("Cancel", role: .cancel) { }
                Button("Rename") { performRename() }
            } message: {
                Text("Enter a new name for this widget.")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No Widgets Yet")
                .font(.title2.bold())

            Text("Create your first widget in the Chat tab and save it to see it here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Widget Grid

    private var widgetGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(savedWidgets) { widget in
                    WidgetCardView(config: widget)
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                        .onTapGesture { editWidget(widget) }
                        .contextMenu { contextMenu(for: widget) }
                }
            }
            .padding()
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenu(for widget: WidgetConfig) -> some View {
        Button {
            editWidget(widget)
        } label: {
            Label("Edit", systemImage: "pencil")
        }

        Button {
            duplicateWidget(widget)
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }

        Button {
            widgetToRename = widget
            renameText = widget.name
            showingRenameAlert = true
        } label: {
            Label("Rename", systemImage: "character.cursor.ibeam")
        }

        Divider()

        Button(role: .destructive) {
            deleteWidget(widget)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Actions

    private func loadWidgets() {
        do {
            savedWidgets = try AppGroupManager.shared.loadAllWidgetConfigs()
                .sorted { ($0.metadata?.updatedAt ?? .distantPast) > ($1.metadata?.updatedAt ?? .distantPast) }
        } catch {
            // If container not available (e.g. simulator), show empty
            savedWidgets = []
        }
    }

    private func editWidget(_ widget: WidgetConfig) {
        var conversation = conversationManager.startNewConversation(family: widget.family)
        conversation.title = "Editing: \(widget.name)"
        conversation.currentConfig = widget
        let editMessage = ConversationMessage(
            role: .assistant,
            content: "Here's your \"\(widget.name)\" widget. How would you like to change it?",
            widgetConfig: widget
        )
        conversation.messages.append(editMessage)
        conversationManager.selectConversation(conversation)
    }

    private func duplicateWidget(_ widget: WidgetConfig) {
        // Check save limit for free tier
        let maxAllowed = storeManager.currentTier.maxSavedWidgets
        if savedWidgets.count >= maxAllowed {
            showingSaveLimitAlert = true
            return
        }

        var duplicate = widget
        duplicate = WidgetConfig(
            schemaVersion: widget.schemaVersion,
            name: "\(widget.name) Copy",
            description: widget.description,
            family: widget.family,
            root: widget.root,
            metadata: WidgetMetadata(
                createdAt: Date(),
                updatedAt: Date(),
                conversationId: widget.metadata?.conversationId,
                tags: widget.metadata?.tags
            ),
            dataBindings: widget.dataBindings
        )
        do {
            try AppGroupManager.shared.saveWidgetConfig(duplicate)
            WidgetReloader.reloadAll()
            loadWidgets()
        } catch {
            errorMessage = "Failed to duplicate: \(error.localizedDescription)"
        }
    }

    private func performRename() {
        guard var widget = widgetToRename else { return }
        widget.name = renameText
        do {
            try AppGroupManager.shared.saveWidgetConfig(widget)
            WidgetReloader.reloadAll()
            loadWidgets()
        } catch {
            errorMessage = "Failed to rename: \(error.localizedDescription)"
        }
    }

    private func deleteWidget(_ widget: WidgetConfig) {
        do {
            try AppGroupManager.shared.deleteWidgetConfig(id: widget.id)
            WidgetReloader.reloadAll()
            loadWidgets()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }
}

#Preview {
    WidgetGalleryView()
        .environment(ConversationManager())
        .environment(StoreManager())
}
