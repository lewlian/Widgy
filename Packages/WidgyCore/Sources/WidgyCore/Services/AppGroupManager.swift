import Foundation

// MARK: - App Group Manager

/// Manages shared storage between the main app and widget extension via App Group container.
public final class AppGroupManager: Sendable {
    public static let shared = AppGroupManager()

    public static let appGroupIdentifier = "group.com.lewlian.Widgy"

    private let containerURL: URL?

    private init() {
        self.containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        )
    }

    // MARK: - Container Access

    public var sharedContainerURL: URL? {
        containerURL
    }

    private var widgetsDirectoryURL: URL? {
        guard let container = containerURL else { return nil }
        let url = container.appendingPathComponent("widgets", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    // MARK: - Widget Config CRUD

    /// Save a widget config to the shared container
    public func saveWidgetConfig(_ config: WidgetConfig) throws {
        guard let dir = widgetsDirectoryURL else {
            throw AppGroupError.containerNotAvailable
        }
        let fileURL = dir.appendingPathComponent("\(config.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(config)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Load a widget config by ID
    public func loadWidgetConfig(id: UUID) throws -> WidgetConfig {
        guard let dir = widgetsDirectoryURL else {
            throw AppGroupError.containerNotAvailable
        }
        let fileURL = dir.appendingPathComponent("\(id.uuidString).json")
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var config = try decoder.decode(WidgetConfig.self, from: data)
        config = SchemaVersion.migrate(config)
        return config
    }

    /// Load all widget configs from the shared container
    public func loadAllWidgetConfigs() throws -> [WidgetConfig] {
        guard let dir = widgetsDirectoryURL else {
            throw AppGroupError.containerNotAvailable
        }
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return fileURLs.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  var config = try? decoder.decode(WidgetConfig.self, from: data) else {
                return nil
            }
            config = SchemaVersion.migrate(config)
            return config
        }
    }

    /// Delete a widget config by ID
    public func deleteWidgetConfig(id: UUID) throws {
        guard let dir = widgetsDirectoryURL else {
            throw AppGroupError.containerNotAvailable
        }
        let fileURL = dir.appendingPathComponent("\(id.uuidString).json")
        try FileManager.default.removeItem(at: fileURL)
    }

    /// List all saved widget config IDs
    public func listWidgetConfigIDs() throws -> [UUID] {
        guard let dir = widgetsDirectoryURL else {
            throw AppGroupError.containerNotAvailable
        }
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        return fileURLs.compactMap { url in
            UUID(uuidString: url.deletingPathExtension().lastPathComponent)
        }
    }
}

// MARK: - Errors

public enum AppGroupError: Error, LocalizedError {
    case containerNotAvailable
    case configNotFound(UUID)

    public var errorDescription: String? {
        switch self {
        case .containerNotAvailable:
            return "App Group shared container is not available. Check entitlements."
        case .configNotFound(let id):
            return "Widget config not found: \(id)"
        }
    }
}
