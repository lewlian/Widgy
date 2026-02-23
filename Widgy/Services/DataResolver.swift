import Foundation
import WidgyCore

// MARK: - Data Resolver

/// Utility that resolves all data bindings for a WidgetConfig.
/// Used by both the main app (for preview) and the widget extension.
@MainActor
public final class DataResolver {
    public static let shared = DataResolver()

    private let registry: DataProviderRegistry

    private init() {
        self.registry = DataProviderRegistry.makeDefault()
    }

    /// Resolve all bindings referenced in a widget config.
    public func resolveBindings(for config: WidgetConfig) async -> [String: String] {
        // Collect which data sources are needed
        let neededSources = extractSources(from: config)
        if neededSources.isEmpty {
            // Always provide date_time as a baseline
            return await registry.resolveBindings(for: [.dateTime])
        }
        // Always include date_time
        var sources = neededSources
        sources.insert(.dateTime)
        return await registry.resolveBindings(for: sources)
    }

    /// Build a full RenderContext with resolved bindings.
    public func makeContext(for config: WidgetConfig, isWidgetExtension: Bool = false) async -> RenderContext {
        let values = await resolveBindings(for: config)
        return RenderContext(bindingValues: values, isWidgetExtension: isWidgetExtension)
    }

    /// Extract which data sources a config references.
    private func extractSources(from config: WidgetConfig) -> Set<DataSource> {
        var sources = Set<DataSource>()

        // Check explicit data bindings
        if let bindings = config.dataBindings {
            for (_, binding) in bindings {
                sources.insert(binding.source)
            }
        }

        return sources
    }
}
