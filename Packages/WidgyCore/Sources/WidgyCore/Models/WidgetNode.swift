import Foundation

// MARK: - Widget Node (Recursive Tree)

/// A single node in the widget's view tree. Each node has a type and type-specific properties.
/// Container nodes (stacks, overlays) have children. Leaf nodes (text, symbol, spacer) do not.
public indirect enum WidgetNode: Codable, Sendable, Equatable {
    case vStack(StackProperties)
    case hStack(StackProperties)
    case zStack(ZStackProperties)
    case text(TextProperties)
    case sfSymbol(SFSymbolProperties)
    case image(ImageProperties)
    case spacer(SpacerProperties?)
    case divider(DividerProperties?)
    case gauge(GaugeProperties)
    case frame(FrameProperties)
    case padding(PaddingProperties)
    case containerRelativeShape(ContainerRelativeShapeProperties?)

    // MARK: - Coding

    enum CodingKeys: String, CodingKey {
        case type
        case properties
        case children
    }

    enum NodeType: String, Codable, Sendable {
        case vStack = "VStack"
        case hStack = "HStack"
        case zStack = "ZStack"
        case text = "Text"
        case sfSymbol = "SFSymbol"
        case image = "Image"
        case spacer = "Spacer"
        case divider = "Divider"
        case gauge = "Gauge"
        case frame = "Frame"
        case padding = "Padding"
        case containerRelativeShape = "ContainerRelativeShape"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(NodeType.self, forKey: .type)

        // Children may appear at node level (AI output) or inside properties (our schema)
        let nodeLevelChildren = try container.decodeIfPresent([WidgetNode].self, forKey: .children)

        switch type {
        case .vStack:
            var props = (try? container.decode(StackProperties.self, forKey: .properties)) ?? StackProperties()
            if props.children.isEmpty, let children = nodeLevelChildren { props.children = children }
            self = .vStack(props)
        case .hStack:
            var props = (try? container.decode(StackProperties.self, forKey: .properties)) ?? StackProperties()
            if props.children.isEmpty, let children = nodeLevelChildren { props.children = children }
            self = .hStack(props)
        case .zStack:
            var props = (try? container.decode(ZStackProperties.self, forKey: .properties)) ?? ZStackProperties()
            if props.children.isEmpty, let children = nodeLevelChildren { props.children = children }
            self = .zStack(props)
        case .text:
            let props = try container.decode(TextProperties.self, forKey: .properties)
            self = .text(props)
        case .sfSymbol:
            let props = try container.decode(SFSymbolProperties.self, forKey: .properties)
            self = .sfSymbol(props)
        case .image:
            let props = try container.decode(ImageProperties.self, forKey: .properties)
            self = .image(props)
        case .spacer:
            let props = try container.decodeIfPresent(SpacerProperties.self, forKey: .properties)
            self = .spacer(props)
        case .divider:
            let props = try container.decodeIfPresent(DividerProperties.self, forKey: .properties)
            self = .divider(props)
        case .gauge:
            let props = try container.decode(GaugeProperties.self, forKey: .properties)
            self = .gauge(props)
        case .frame:
            let props = try container.decode(FrameProperties.self, forKey: .properties)
            self = .frame(props)
        case .padding:
            let props = try container.decode(PaddingProperties.self, forKey: .properties)
            self = .padding(props)
        case .containerRelativeShape:
            let props = try container.decodeIfPresent(ContainerRelativeShapeProperties.self, forKey: .properties)
            self = .containerRelativeShape(props)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .vStack(let props):
            try container.encode(NodeType.vStack, forKey: .type)
            try container.encode(props, forKey: .properties)
        case .hStack(let props):
            try container.encode(NodeType.hStack, forKey: .type)
            try container.encode(props, forKey: .properties)
        case .zStack(let props):
            try container.encode(NodeType.zStack, forKey: .type)
            try container.encode(props, forKey: .properties)
        case .text(let props):
            try container.encode(NodeType.text, forKey: .type)
            try container.encode(props, forKey: .properties)
        case .sfSymbol(let props):
            try container.encode(NodeType.sfSymbol, forKey: .type)
            try container.encode(props, forKey: .properties)
        case .image(let props):
            try container.encode(NodeType.image, forKey: .type)
            try container.encode(props, forKey: .properties)
        case .spacer(let props):
            try container.encode(NodeType.spacer, forKey: .type)
            try container.encodeIfPresent(props, forKey: .properties)
        case .divider(let props):
            try container.encode(NodeType.divider, forKey: .type)
            try container.encodeIfPresent(props, forKey: .properties)
        case .gauge(let props):
            try container.encode(NodeType.gauge, forKey: .type)
            try container.encode(props, forKey: .properties)
        case .frame(let props):
            try container.encode(NodeType.frame, forKey: .type)
            try container.encode(props, forKey: .properties)
        case .padding(let props):
            try container.encode(NodeType.padding, forKey: .type)
            try container.encode(props, forKey: .properties)
        case .containerRelativeShape(let props):
            try container.encode(NodeType.containerRelativeShape, forKey: .type)
            try container.encodeIfPresent(props, forKey: .properties)
        }
    }
}
