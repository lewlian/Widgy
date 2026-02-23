import Foundation

// MARK: - Stack Properties (VStack, HStack)

public struct StackProperties: Codable, Sendable, Equatable {
    public var children: [WidgetNode]
    public var alignment: StackAlignment?
    public var spacing: CGFloat?
    public var style: NodeStyle?

    public init(
        children: [WidgetNode],
        alignment: StackAlignment? = nil,
        spacing: CGFloat? = nil,
        style: NodeStyle? = nil
    ) {
        self.children = children
        self.alignment = alignment
        self.spacing = spacing
        self.style = style
    }
}

public enum StackAlignment: String, Codable, Sendable {
    case leading, center, trailing  // VStack
    case top, bottom                // HStack
    case firstTextBaseline, lastTextBaseline
}

// MARK: - ZStack Properties

public struct ZStackProperties: Codable, Sendable, Equatable {
    public var children: [WidgetNode]
    public var alignment: ZStackAlignment?
    public var style: NodeStyle?

    public init(
        children: [WidgetNode],
        alignment: ZStackAlignment? = nil,
        style: NodeStyle? = nil
    ) {
        self.children = children
        self.alignment = alignment
        self.style = style
    }
}

public enum ZStackAlignment: String, Codable, Sendable {
    case center, leading, trailing
    case top, bottom
    case topLeading, topTrailing
    case bottomLeading, bottomTrailing
}

// MARK: - Text Properties

public struct TextProperties: Codable, Sendable, Equatable {
    public var content: String
    public var font: FontDescriptor?
    public var color: ColorValue?
    public var alignment: TextAlignment?
    public var lineLimit: Int?
    public var minimumScaleFactor: CGFloat?
    public var style: NodeStyle?

    public init(
        content: String,
        font: FontDescriptor? = nil,
        color: ColorValue? = nil,
        alignment: TextAlignment? = nil,
        lineLimit: Int? = nil,
        minimumScaleFactor: CGFloat? = nil,
        style: NodeStyle? = nil
    ) {
        self.content = content
        self.font = font
        self.color = color
        self.alignment = alignment
        self.lineLimit = lineLimit
        self.minimumScaleFactor = minimumScaleFactor
        self.style = style
    }
}

public enum TextAlignment: String, Codable, Sendable {
    case leading, center, trailing
}

// MARK: - SF Symbol Properties

public struct SFSymbolProperties: Codable, Sendable, Equatable {
    public var systemName: String
    public var color: ColorValue?
    public var fontSize: CGFloat?
    public var fontWeight: FontWeight?
    public var renderingMode: SymbolRenderingMode?
    public var style: NodeStyle?

    public init(
        systemName: String,
        color: ColorValue? = nil,
        fontSize: CGFloat? = nil,
        fontWeight: FontWeight? = nil,
        renderingMode: SymbolRenderingMode? = nil,
        style: NodeStyle? = nil
    ) {
        self.systemName = systemName
        self.color = color
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.renderingMode = renderingMode
        self.style = style
    }

    enum CodingKeys: String, CodingKey {
        case systemName = "system_name"
        case color
        case fontSize = "font_size"
        case fontWeight = "font_weight"
        case renderingMode = "rendering_mode"
        case style
    }
}

public enum SymbolRenderingMode: String, Codable, Sendable {
    case monochrome, multicolor, hierarchical, palette
}

// MARK: - Image Properties

public struct ImageProperties: Codable, Sendable, Equatable {
    public var source: ImageSource
    public var contentMode: ImageContentMode?
    public var cornerRadius: CGFloat?
    public var style: NodeStyle?

    public init(
        source: ImageSource,
        contentMode: ImageContentMode? = nil,
        cornerRadius: CGFloat? = nil,
        style: NodeStyle? = nil
    ) {
        self.source = source
        self.contentMode = contentMode
        self.cornerRadius = cornerRadius
        self.style = style
    }

    enum CodingKeys: String, CodingKey {
        case source
        case contentMode = "content_mode"
        case cornerRadius = "corner_radius"
        case style
    }
}

public enum ImageSource: Codable, Sendable, Equatable {
    case asset(String)
    case remote(String)
    case data(String) // base64

    enum CodingKeys: String, CodingKey {
        case type, value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)
        switch type {
        case "asset": self = .asset(value)
        case "remote": self = .remote(value)
        case "data": self = .data(value)
        default: self = .asset(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .asset(let name):
            try container.encode("asset", forKey: .type)
            try container.encode(name, forKey: .value)
        case .remote(let url):
            try container.encode("remote", forKey: .type)
            try container.encode(url, forKey: .value)
        case .data(let base64):
            try container.encode("data", forKey: .type)
            try container.encode(base64, forKey: .value)
        }
    }
}

public enum ImageContentMode: String, Codable, Sendable {
    case fit, fill
}

// MARK: - Spacer Properties

public struct SpacerProperties: Codable, Sendable, Equatable {
    public var minLength: CGFloat?

    public init(minLength: CGFloat? = nil) {
        self.minLength = minLength
    }

    enum CodingKeys: String, CodingKey {
        case minLength = "min_length"
    }
}

// MARK: - Divider Properties

public struct DividerProperties: Codable, Sendable, Equatable {
    public var color: ColorValue?
    public var thickness: CGFloat?
    public var style: NodeStyle?

    public init(color: ColorValue? = nil, thickness: CGFloat? = nil, style: NodeStyle? = nil) {
        self.color = color
        self.thickness = thickness
        self.style = style
    }
}

// MARK: - Gauge Properties

public struct GaugeProperties: Codable, Sendable, Equatable {
    public var value: Double
    public var minValue: Double?
    public var maxValue: Double?
    public var label: String?
    public var currentValueLabel: String?
    public var gaugeStyle: GaugeStyle?
    public var tint: ColorValue?
    public var style: NodeStyle?

    public init(
        value: Double,
        minValue: Double? = nil,
        maxValue: Double? = nil,
        label: String? = nil,
        currentValueLabel: String? = nil,
        gaugeStyle: GaugeStyle? = nil,
        tint: ColorValue? = nil,
        style: NodeStyle? = nil
    ) {
        self.value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.label = label
        self.currentValueLabel = currentValueLabel
        self.gaugeStyle = gaugeStyle
        self.tint = tint
        self.style = style
    }

    enum CodingKeys: String, CodingKey {
        case value
        case minValue = "min_value"
        case maxValue = "max_value"
        case label
        case currentValueLabel = "current_value_label"
        case gaugeStyle = "gauge_style"
        case tint
        case style
    }
}

public enum GaugeStyle: String, Codable, Sendable {
    case automatic, linear, circular, accessoryCircular, accessoryLinear
}

// MARK: - Frame Properties

public struct FrameProperties: Codable, Sendable, Equatable {
    public var child: WidgetNode
    public var width: CGFloat?
    public var height: CGFloat?
    public var minWidth: CGFloat?
    public var maxWidth: CGFloat?
    public var minHeight: CGFloat?
    public var maxHeight: CGFloat?
    public var alignment: ZStackAlignment?
    public var style: NodeStyle?

    public init(
        child: WidgetNode,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        minWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        alignment: ZStackAlignment? = nil,
        style: NodeStyle? = nil
    ) {
        self.child = child
        self.width = width
        self.height = height
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.alignment = alignment
        self.style = style
    }

    enum CodingKeys: String, CodingKey {
        case child
        case width, height
        case minWidth = "min_width"
        case maxWidth = "max_width"
        case minHeight = "min_height"
        case maxHeight = "max_height"
        case alignment
        case style
    }
}

// MARK: - Padding Properties

public struct PaddingProperties: Codable, Sendable, Equatable {
    public var child: WidgetNode
    public var edges: PaddingEdges?
    public var value: CGFloat?
    public var style: NodeStyle?

    public init(
        child: WidgetNode,
        edges: PaddingEdges? = nil,
        value: CGFloat? = nil,
        style: NodeStyle? = nil
    ) {
        self.child = child
        self.edges = edges
        self.value = value
        self.style = style
    }
}

public enum PaddingEdges: String, Codable, Sendable {
    case all, horizontal, vertical
    case top, bottom, leading, trailing
}

// MARK: - ContainerRelativeShape Properties

public struct ContainerRelativeShapeProperties: Codable, Sendable, Equatable {
    public var fill: ColorValue?
    public var style: NodeStyle?

    public init(fill: ColorValue? = nil, style: NodeStyle? = nil) {
        self.fill = fill
        self.style = style
    }
}

// MARK: - Infinity Support

public enum FlexibleDimension: Codable, Sendable, Equatable {
    case fixed(CGFloat)
    case infinity

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringVal = try? container.decode(String.self), stringVal == "infinity" {
            self = .infinity
        } else {
            let value = try container.decode(CGFloat.self)
            self = .fixed(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fixed(let value): try container.encode(value)
        case .infinity: try container.encode("infinity")
        }
    }

    public var cgFloat: CGFloat {
        switch self {
        case .fixed(let v): return v
        case .infinity: return .infinity
        }
    }
}
