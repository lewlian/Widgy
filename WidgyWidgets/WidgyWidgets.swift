import WidgetKit
import SwiftUI
import AppIntents
import WidgyCore

// MARK: - Widget Selection Intent

struct SelectWidgetIntent: AppIntent, WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select Widget"
    static let description: IntentDescription = "Choose which saved widget to display"

    @Parameter(title: "Widget")
    var widgetEntity: WidgetEntity?

    func perform() async throws -> some IntentResult {
        .result()
    }
}

// MARK: - Widget Entity

struct WidgetEntity: AppEntity {
    var id: String
    var name: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Widget"
    static let defaultQuery = WidgetEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct WidgetEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [WidgetEntity] {
        let configs = (try? AppGroupManager.shared.loadAllWidgetConfigs()) ?? []
        return configs
            .filter { identifiers.contains($0.id.uuidString) }
            .map { WidgetEntity(id: $0.id.uuidString, name: $0.name) }
    }

    func suggestedEntities() async throws -> [WidgetEntity] {
        let configs = (try? AppGroupManager.shared.loadAllWidgetConfigs()) ?? []
        return configs.map { WidgetEntity(id: $0.id.uuidString, name: $0.name) }
    }

    func defaultResult() async -> WidgetEntity? {
        let configs = (try? AppGroupManager.shared.loadAllWidgetConfigs()) ?? []
        return configs.first.map { WidgetEntity(id: $0.id.uuidString, name: $0.name) }
    }
}

// MARK: - Timeline Provider

struct WidgyTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WidgyTimelineEntry {
        WidgyTimelineEntry(date: Date(), config: SampleConfigs.simpleClock, resolvedBindings: nil)
    }

    func snapshot(for configuration: SelectWidgetIntent, in context: Context) async -> WidgyTimelineEntry {
        let config = loadConfig(for: configuration) ?? SampleConfigs.simpleClock
        let bindings = await resolveBindings(for: config)
        return WidgyTimelineEntry(date: Date(), config: config, resolvedBindings: bindings)
    }

    func timeline(for configuration: SelectWidgetIntent, in context: Context) async -> Timeline<WidgyTimelineEntry> {
        let config = loadConfig(for: configuration)
        let bindings = await resolveBindings(for: config)
        let entry = WidgyTimelineEntry(date: Date(), config: config, resolvedBindings: bindings)

        // Refresh every 15 minutes for data-bound widgets, every hour for static
        let hasBindings = config?.dataBindings?.isEmpty == false
        let refreshInterval: TimeInterval = hasBindings ? 900 : 3600
        let nextRefresh = Date().addingTimeInterval(refreshInterval)

        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func resolveBindings(for config: WidgetConfig?) async -> [String: String] {
        let registry = DataProviderRegistry.makeDefault()
        // Scan the config tree for all {{source.field}} placeholders to determine needed sources
        var sources: Set<DataSource> = [.dateTime]
        if let config {
            let placeholders = scanPlaceholders(in: config.root)
            for (sourceName, _) in placeholders {
                if let source = DataSource(rawValue: sourceName) {
                    sources.insert(source)
                }
            }
        }
        return await registry.resolveBindings(for: sources)
    }

    private func scanPlaceholders(in node: WidgetNode) -> [(source: String, field: String)] {
        var results: [(String, String)] = []
        switch node {
        case .text(let props):
            results.append(contentsOf: BindingResolution.extractPlaceholders(from: props.content))
        case .vStack(let props):
            for child in props.children { results.append(contentsOf: scanPlaceholders(in: child)) }
        case .hStack(let props):
            for child in props.children { results.append(contentsOf: scanPlaceholders(in: child)) }
        case .zStack(let props):
            for child in props.children { results.append(contentsOf: scanPlaceholders(in: child)) }
        case .frame(let props):
            results.append(contentsOf: scanPlaceholders(in: props.child))
        case .padding(let props):
            results.append(contentsOf: scanPlaceholders(in: props.child))
        case .gauge(let props):
            if let label = props.currentValueLabel {
                results.append(contentsOf: BindingResolution.extractPlaceholders(from: label))
            }
        default: break
        }
        return results
    }

    private func loadConfig(for intent: SelectWidgetIntent) -> WidgetConfig? {
        guard let entityID = intent.widgetEntity?.id,
              let uuid = UUID(uuidString: entityID) else {
            // No widget selected — return first available or sample
            return (try? AppGroupManager.shared.loadAllWidgetConfigs())?.first
        }
        return try? AppGroupManager.shared.loadWidgetConfig(id: uuid)
    }
}

// MARK: - Timeline Entry

struct WidgyTimelineEntry: TimelineEntry {
    let date: Date
    let config: WidgetConfig?
    let resolvedBindings: [String: String]?
}

// MARK: - Widget View

struct WidgyWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: WidgyTimelineEntry

    private var isLockScreen: Bool {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return true
        default:
            return false
        }
    }

    var body: some View {
        if isLockScreen {
            lockScreenBody
        } else {
            homeScreenBody
        }
    }

    // MARK: - Home Screen

    private var homeScreenBody: some View {
        Group {
            if let config = entry.config {
                WidgetConfigRenderer(config: config, context: makeContext())
            } else {
                emptyStateView
            }
        }
        .containerBackground(for: .widget) {
            extractBackgroundColor(from: entry.config)
        }
    }

    /// Extract the background fill color from the config's node tree.
    /// Looks for a ContainerRelativeShape in the root ZStack (the typical pattern).
    private func extractBackgroundColor(from config: WidgetConfig?) -> Color {
        guard let config else { return Color(.systemBackground) }
        if case .zStack(let props) = config.root {
            for child in props.children {
                if case .containerRelativeShape(let bgProps) = child,
                   let fill = bgProps?.fill {
                    return ColorRenderer.resolve(fill)
                }
            }
        }
        return Color(.systemBackground)
    }

    // MARK: - Lock Screen

    @ViewBuilder
    private var lockScreenBody: some View {
        switch family {
        case .accessoryInline:
            lockScreenInline
        case .accessoryCircular:
            lockScreenCircular
                .containerBackground(.clear, for: .widget)
        case .accessoryRectangular:
            lockScreenRectangular
                .containerBackground(.clear, for: .widget)
        default:
            EmptyView()
        }
    }

    private var lockScreenInline: some View {
        ViewThatFits {
            if let config = entry.config {
                Text(config.name)
                    .widgetAccentable()
            } else {
                Text("Widgy")
                    .widgetAccentable()
            }
        }
    }

    private var lockScreenCircular: some View {
        Group {
            if let config = entry.config {
                WidgetConfigRenderer(config: config, context: makeContext())
                    .widgetAccentable()
            } else {
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .widgetAccentable()
                }
            }
        }
    }

    private var lockScreenRectangular: some View {
        Group {
            if let config = entry.config {
                WidgetConfigRenderer(config: config, context: makeContext())
                    .widgetAccentable()
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Widgy")
                        .font(.headline)
                        .widgetAccentable()
                    Text("Open app to create a widget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 4) {
            Image(systemName: "plus.circle")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Open Widgy to create")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func makeContext() -> RenderContext {
        // Synchronously provide date/time as baseline, other providers
        // are pre-resolved via the timeline provider
        let now = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let calendar = Calendar.current

        var values: [String: String] = [
            "date_time.time": timeFormatter.string(from: now),
            "date_time.date": dateFormatter.string(from: now),
            "date_time.hour": "\(calendar.component(.hour, from: now))",
            "date_time.minute": String(format: "%02d", calendar.component(.minute, from: now)),
            "date_time.weekday": weekdayFormatter.string(from: now),
            "date_time.month": monthFormatter.string(from: now),
            "date_time.year": "\(calendar.component(.year, from: now))",
        ]

        // Merge any pre-resolved values from the timeline entry
        if let preResolved = entry.resolvedBindings {
            values.merge(preResolved) { _, new in new }
        }

        return RenderContext(
            bindingValues: values,
            isWidgetExtension: true
        )
    }
}

// MARK: - Widget Definition

struct WidgyWidget: Widget {
    let kind: String = "WidgyWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectWidgetIntent.self, provider: WidgyTimelineProvider()) { entry in
            WidgyWidgetView(entry: entry)
        }
        .configurationDisplayName("Widgy")
        .description("AI-powered custom widgets")
        .containerBackgroundRemovable(false)
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

// MARK: - Widget Bundle

@main
struct WidgyWidgetBundle: WidgetBundle {
    var body: some Widget {
        WidgyWidget()
    }
}
