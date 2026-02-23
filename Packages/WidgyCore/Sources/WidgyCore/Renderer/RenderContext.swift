import Foundation

// MARK: - Render Context

/// Context passed through the rendering tree for data binding resolution and configuration.
public struct RenderContext: Sendable {
    /// Resolved data binding values: "source.field" -> "display value"
    public var bindingValues: [String: String]

    /// Whether we're rendering in a widget extension (affects some behavior)
    public var isWidgetExtension: Bool

    public static let `default` = RenderContext(bindingValues: [:], isWidgetExtension: false)

    public init(bindingValues: [String: String], isWidgetExtension: Bool = false) {
        self.bindingValues = bindingValues
        self.isWidgetExtension = isWidgetExtension
    }

    /// Resolve any {{source.field}} placeholders in text
    public func resolveBindings(in text: String) -> String {
        BindingResolution.resolve(text: text, values: bindingValues)
    }
}
