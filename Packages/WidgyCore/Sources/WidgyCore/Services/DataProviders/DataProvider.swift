import Foundation

// MARK: - Data Provider Protocol

/// Protocol for data source providers that resolve binding placeholders.
public protocol DataProvider: Sendable {
    /// The data source this provider handles
    var source: DataSource { get }

    /// Fetch current values for all fields this provider supports.
    /// Returns dictionary keyed by "source.field" (e.g., "date_time.hour").
    func fetchValues() async throws -> [String: String]
}

// MARK: - Data Provider Registry

/// Registry that holds all data providers and resolves bindings for widget configs.
public final class DataProviderRegistry: Sendable {
    private let providers: [DataSource: DataProvider]

    public init(providers: [DataProvider] = []) {
        var map: [DataSource: DataProvider] = [:]
        for provider in providers {
            map[provider.source] = provider
        }
        self.providers = map
    }

    /// Create a registry with all available default providers.
    public static func makeDefault() -> DataProviderRegistry {
        var allProviders: [DataProvider] = [
            DateTimeProvider(),
            BatteryProvider(),
            CalendarProvider(),
            LocationProvider(),
        ]
        #if canImport(WeatherKit)
        allProviders.append(WeatherProvider())
        #endif
        #if canImport(HealthKit)
        allProviders.append(HealthProvider())
        #endif
        return DataProviderRegistry(providers: allProviders)
    }

    /// Resolve all binding values needed by a set of data sources.
    public func resolveBindings(for sources: Set<DataSource>) async -> [String: String] {
        var allValues: [String: String] = [:]
        await withTaskGroup(of: [String: String].self) { group in
            for source in sources {
                guard let provider = providers[source] else { continue }
                group.addTask {
                    (try? await provider.fetchValues()) ?? [:]
                }
            }
            for await values in group {
                allValues.merge(values) { _, new in new }
            }
        }
        return allValues
    }

    /// Resolve all bindings from all registered providers.
    public func resolveAllBindings() async -> [String: String] {
        let allSources = Set(providers.keys)
        return await resolveBindings(for: allSources)
    }
}
