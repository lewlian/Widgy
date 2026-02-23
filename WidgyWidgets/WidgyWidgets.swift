import WidgetKit
import SwiftUI
import WidgyCore

// MARK: - Timeline Provider

struct WidgyTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgyTimelineEntry {
        WidgyTimelineEntry(date: Date(), config: SampleConfigs.simpleClock)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgyTimelineEntry) -> Void) {
        let entry = WidgyTimelineEntry(date: Date(), config: SampleConfigs.simpleClock)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgyTimelineEntry>) -> Void) {
        let entry = WidgyTimelineEntry(date: Date(), config: SampleConfigs.simpleClock)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct WidgyTimelineEntry: TimelineEntry {
    let date: Date
    let config: WidgetConfig?
}

// MARK: - Widget View

struct WidgyWidgetView: View {
    let entry: WidgyTimelineEntry

    var body: some View {
        if let config = entry.config {
            // Placeholder — renderer comes in Phase 2
            VStack {
                Text(config.name)
                    .font(.headline)
                Text("Widget Preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            VStack {
                Image(systemName: "widget.small")
                    .font(.title)
                Text("Tap to configure")
                    .font(.caption)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

// MARK: - Widget Definition

struct WidgyWidget: Widget {
    let kind: String = "WidgyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgyTimelineProvider()) { entry in
            WidgyWidgetView(entry: entry)
        }
        .configurationDisplayName("Widgy")
        .description("AI-powered custom widgets")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle

@main
struct WidgyWidgetBundle: WidgetBundle {
    var body: some Widget {
        WidgyWidget()
    }
}
