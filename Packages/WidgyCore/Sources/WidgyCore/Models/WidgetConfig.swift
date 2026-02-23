import Foundation

// MARK: - Top-Level Widget Config

/// The root configuration object for a Widgy widget.
/// This is the central contract between the AI, the renderer, and persistence.
public struct WidgetConfig: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public var schemaVersion: String
    public var name: String
    public var description: String?
    public var family: WidgetFamily
    public var root: WidgetNode
    public var metadata: WidgetMetadata?
    public var dataBindings: [String: DataBinding]?

    public init(
        id: UUID = UUID(),
        schemaVersion: String = SchemaVersion.current,
        name: String,
        description: String? = nil,
        family: WidgetFamily = .systemSmall,
        root: WidgetNode,
        metadata: WidgetMetadata? = nil,
        dataBindings: [String: DataBinding]? = nil
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.name = name
        self.description = description
        self.family = family
        self.root = root
        self.metadata = metadata
        self.dataBindings = dataBindings
    }

    enum CodingKeys: String, CodingKey {
        case id
        case schemaVersion = "schema_version"
        case name
        case description
        case family
        case root
        case metadata
        case dataBindings = "data_bindings"
    }
}

// MARK: - Schema Version

public enum SchemaVersion {
    public static let current = "1.0"

    /// Migrate a config from an older schema version to the current version.
    /// Returns the config unchanged if already current or if no migration path exists.
    public static func migrate(_ config: WidgetConfig) -> WidgetConfig {
        var migrated = config
        switch config.schemaVersion {
        // Future migrations go here:
        // case "1.0":
        //     migrated = migrateV1ToV2(migrated)
        //     migrated.schemaVersion = "2.0"
        //     fallthrough
        default:
            break
        }
        migrated.schemaVersion = current
        return migrated
    }
}

// MARK: - Widget Family

public enum WidgetFamily: String, Codable, Sendable, CaseIterable {
    case systemSmall
    case systemMedium
    case systemLarge
    case accessoryCircular
    case accessoryRectangular
    case accessoryInline
}

// MARK: - Widget Metadata

public struct WidgetMetadata: Codable, Sendable, Equatable {
    public var createdAt: Date?
    public var updatedAt: Date?
    public var conversationId: UUID?
    public var tags: [String]?
    public var thumbnailData: Data?

    public init(
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        conversationId: UUID? = nil,
        tags: [String]? = nil,
        thumbnailData: Data? = nil
    ) {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.conversationId = conversationId
        self.tags = tags
        self.thumbnailData = thumbnailData
    }

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case conversationId = "conversation_id"
        case tags
        case thumbnailData = "thumbnail_data"
    }
}
