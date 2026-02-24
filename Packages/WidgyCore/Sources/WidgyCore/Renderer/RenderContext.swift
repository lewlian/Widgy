import Foundation

// MARK: - Render Context

/// Context passed through the rendering tree for data binding resolution and configuration.
public struct RenderContext: Sendable {
    /// Resolved data binding values: "source.field" -> "display value"
    public var bindingValues: [String: String]

    /// Whether we're rendering in a widget extension (affects some behavior)
    public var isWidgetExtension: Bool

    public static let `default` = RenderContext(bindingValues: [:], isWidgetExtension: false)

    /// Preview context with sample data for in-app widget previews
    public static let preview = RenderContext(bindingValues: [
        "date_time.time": "9:41",
        "date_time.date": "Mon, Feb 23",
        "date_time.day": "Monday",
        "date_time.month": "February",
        "date_time.year": "2026",
        "date_time.hour": "9",
        "date_time.minute": "41",
        "weather.temperature": "24°",
        "weather.condition": "Sunny",
        "weather.high": "28°",
        "weather.low": "19°",
        "weather.icon": "sun.max.fill",
        "battery.level": "85%",
        "battery.state": "Charging",
        "calendar.next.title": "Team Standup",
        "calendar.next.time": "10:00 AM",
        "calendar.next.location": "Zoom",
        "health.steps": "4,328",
        "health.calories": "312",
        "location.city": "Singapore",
        "location.country": "SG",
    ], isWidgetExtension: false)

    public init(bindingValues: [String: String], isWidgetExtension: Bool = false) {
        self.bindingValues = bindingValues
        self.isWidgetExtension = isWidgetExtension
    }

    /// Resolve any {{source.field}} placeholders in text
    public func resolveBindings(in text: String) -> String {
        BindingResolution.resolve(text: text, values: bindingValues)
    }
}
