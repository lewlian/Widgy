import Foundation

// MARK: - Data Binding

/// Represents a data binding that resolves dynamic content at render time.
/// Placeholder format in text: {{source.field}} e.g., {{weather.temperature}}, {{battery.level}}
public struct DataBinding: Codable, Sendable, Equatable {
    public var source: DataSource
    public var field: String
    public var format: String?
    public var fallback: String?

    public init(
        source: DataSource,
        field: String,
        format: String? = nil,
        fallback: String? = nil
    ) {
        self.source = source
        self.field = field
        self.format = format
        self.fallback = fallback
    }
}

// MARK: - Data Source

public enum DataSource: String, Codable, Sendable, CaseIterable {
    case weather
    case calendar
    case health
    case battery
    case dateTime = "date_time"
    case location
    case device
    case contacts
    case music
    case reminders
}

// MARK: - Binding Resolution

public enum BindingResolution {
    /// Regex pattern matching {{source.field}} placeholders
    public nonisolated(unsafe) static let placeholderPattern = /\{\{(\w+)\.(\w+)\}\}/

    /// Extract all binding placeholders from a text string
    public static func extractPlaceholders(from text: String) -> [(source: String, field: String)] {
        let matches = text.matches(of: placeholderPattern)
        return matches.map { match in
            (source: String(match.output.1), field: String(match.output.2))
        }
    }

    /// Replace placeholders in text with resolved values
    public static func resolve(text: String, values: [String: String]) -> String {
        var result = text
        for (key, value) in values {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return result
    }
}
