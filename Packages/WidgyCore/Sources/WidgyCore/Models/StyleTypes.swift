import Foundation

// MARK: - Node Style (common styling applied to any node)

public struct NodeStyle: Codable, Sendable, Equatable {
    public var background: BackgroundValue?
    public var cornerRadius: CGFloat?
    public var opacity: Double?
    public var shadow: ShadowDescriptor?
    public var border: BorderDescriptor?
    public var glassEffect: Bool?

    public init(
        background: BackgroundValue? = nil,
        cornerRadius: CGFloat? = nil,
        opacity: Double? = nil,
        shadow: ShadowDescriptor? = nil,
        border: BorderDescriptor? = nil,
        glassEffect: Bool? = nil
    ) {
        self.background = background
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.shadow = shadow
        self.border = border
        self.glassEffect = glassEffect
    }

    enum CodingKeys: String, CodingKey {
        case background
        case cornerRadius = "corner_radius"
        case opacity
        case shadow
        case border
        case glassEffect = "glass_effect"
    }
}

// MARK: - Color Value

public enum ColorValue: Codable, Sendable, Equatable {
    case hex(String)
    case system(SystemColor)
    case semantic(SemanticColor)

    enum CodingKeys: String, CodingKey {
        case type, value
    }

    public init(from decoder: Decoder) throws {
        // Support shorthand: just a hex string like "#FF0000"
        if let container = try? decoder.singleValueContainer(),
           let stringValue = try? container.decode(String.self) {
            if stringValue.hasPrefix("#") {
                self = .hex(stringValue)
            } else if let system = SystemColor(rawValue: stringValue) {
                self = .system(system)
            } else if let semantic = SemanticColor(rawValue: stringValue) {
                self = .semantic(semantic)
            } else {
                self = .hex(stringValue)
            }
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)

        switch type {
        case "hex": self = .hex(value)
        case "system":
            self = .system(SystemColor(rawValue: value) ?? .blue)
        case "semantic":
            self = .semantic(SemanticColor(rawValue: value) ?? .primary)
        default: self = .hex(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .hex(let hex):
            try container.encode("hex", forKey: .type)
            try container.encode(hex, forKey: .value)
        case .system(let color):
            try container.encode("system", forKey: .type)
            try container.encode(color.rawValue, forKey: .value)
        case .semantic(let color):
            try container.encode("semantic", forKey: .type)
            try container.encode(color.rawValue, forKey: .value)
        }
    }
}

public enum SystemColor: String, Codable, Sendable {
    case red, orange, yellow, green, mint, teal, cyan
    case blue, indigo, purple, pink, brown
    case white, black, gray, clear
}

public enum SemanticColor: String, Codable, Sendable {
    case primary, secondary
    case label, secondaryLabel, tertiaryLabel
    case systemBackground, secondarySystemBackground
    case separator
    case accent
}

// MARK: - Background Value

public enum BackgroundValue: Codable, Sendable, Equatable {
    case color(ColorValue)
    case gradient(GradientDescriptor)

    enum CodingKeys: String, CodingKey {
        case type
        case color
        case gradient
    }

    public init(from decoder: Decoder) throws {
        // Try as a simple color string first
        if let container = try? decoder.singleValueContainer(),
           let stringValue = try? container.decode(String.self) {
            self = .color(.hex(stringValue))
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "color":
            let color = try container.decode(ColorValue.self, forKey: .color)
            self = .color(color)
        case "gradient":
            let gradient = try container.decode(GradientDescriptor.self, forKey: .gradient)
            self = .gradient(gradient)
        default:
            self = .color(.system(.clear))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .color(let color):
            try container.encode("color", forKey: .type)
            try container.encode(color, forKey: .color)
        case .gradient(let gradient):
            try container.encode("gradient", forKey: .type)
            try container.encode(gradient, forKey: .gradient)
        }
    }
}

// MARK: - Gradient

public struct GradientDescriptor: Codable, Sendable, Equatable {
    public var type: GradientType
    public var colors: [ColorValue]
    public var startPoint: GradientPoint?
    public var endPoint: GradientPoint?

    public init(
        type: GradientType = .linear,
        colors: [ColorValue],
        startPoint: GradientPoint? = nil,
        endPoint: GradientPoint? = nil
    ) {
        self.type = type
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
    }

    enum CodingKeys: String, CodingKey {
        case type, colors
        case startPoint = "start_point"
        case endPoint = "end_point"
    }
}

public enum GradientType: String, Codable, Sendable {
    case linear, radial, angular
}

public struct GradientPoint: Codable, Sendable, Equatable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

// MARK: - Font Descriptor

public struct FontDescriptor: Codable, Sendable, Equatable {
    public var style: FontStyle?
    public var size: CGFloat?
    public var weight: FontWeight?
    public var design: FontDesign?

    public init(
        style: FontStyle? = nil,
        size: CGFloat? = nil,
        weight: FontWeight? = nil,
        design: FontDesign? = nil
    ) {
        self.style = style
        self.size = size
        self.weight = weight
        self.design = design
    }
}

public enum FontStyle: String, Codable, Sendable {
    case largeTitle, title, title2, title3
    case headline, subheadline
    case body, callout, footnote, caption, caption2
}

public enum FontWeight: String, Codable, Sendable {
    case ultraLight, thin, light, regular
    case medium, semibold, bold, heavy, black
}

public enum FontDesign: String, Codable, Sendable {
    case `default`, rounded, serif, monospaced
}

// MARK: - Shadow Descriptor

public struct ShadowDescriptor: Codable, Sendable, Equatable {
    public var color: ColorValue?
    public var radius: CGFloat
    public var x: CGFloat?
    public var y: CGFloat?

    public init(color: ColorValue? = nil, radius: CGFloat, x: CGFloat? = nil, y: CGFloat? = nil) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - Border Descriptor

public struct BorderDescriptor: Codable, Sendable, Equatable {
    public var color: ColorValue
    public var width: CGFloat

    public init(color: ColorValue, width: CGFloat = 1) {
        self.color = color
        self.width = width
    }
}
