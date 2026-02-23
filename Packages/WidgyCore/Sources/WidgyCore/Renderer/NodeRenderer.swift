import SwiftUI

// MARK: - Node Renderer

/// Recursive SwiftUI renderer that interprets WidgetNode trees into native views.
/// This is the core rendering engine shared between the main app (for previews)
/// and the widget extension (for actual homescreen widgets).
public struct NodeRenderer: View {
    let node: WidgetNode
    let context: RenderContext

    public init(node: WidgetNode, context: RenderContext = .default) {
        self.node = node
        self.context = context
    }

    public var body: some View {
        renderNode(node)
    }

    @ViewBuilder
    private func renderNode(_ node: WidgetNode) -> some View {
        switch node {
        case .vStack(let props):
            renderVStack(props)
        case .hStack(let props):
            renderHStack(props)
        case .zStack(let props):
            renderZStack(props)
        case .text(let props):
            renderText(props)
        case .sfSymbol(let props):
            renderSFSymbol(props)
        case .image(let props):
            renderImage(props)
        case .spacer(let props):
            Spacer(minLength: props?.minLength)
        case .divider(let props):
            renderDivider(props)
        case .gauge(let props):
            renderGauge(props)
        case .frame(let props):
            renderFrame(props)
        case .padding(let props):
            renderPadding(props)
        case .containerRelativeShape(let props):
            renderContainerRelativeShape(props)
        }
    }

    // MARK: - Stack Renderers

    @ViewBuilder
    private func renderVStack(_ props: StackProperties) -> some View {
        let alignment = mapHorizontalAlignment(props.alignment)
        VStack(alignment: alignment, spacing: props.spacing) {
            ForEach(Array(props.children.enumerated()), id: \.offset) { _, child in
                NodeRenderer(node: child, context: context)
            }
        }
        .applyNodeStyle(props.style)
    }

    @ViewBuilder
    private func renderHStack(_ props: StackProperties) -> some View {
        let alignment = mapVerticalAlignment(props.alignment)
        HStack(alignment: alignment, spacing: props.spacing) {
            ForEach(Array(props.children.enumerated()), id: \.offset) { _, child in
                NodeRenderer(node: child, context: context)
            }
        }
        .applyNodeStyle(props.style)
    }

    @ViewBuilder
    private func renderZStack(_ props: ZStackProperties) -> some View {
        let alignment = mapAlignment(props.alignment)
        ZStack(alignment: alignment) {
            ForEach(Array(props.children.enumerated()), id: \.offset) { _, child in
                NodeRenderer(node: child, context: context)
            }
        }
        .applyNodeStyle(props.style)
    }

    // MARK: - Leaf Renderers

    @ViewBuilder
    private func renderText(_ props: TextProperties) -> some View {
        let content = context.resolveBindings(in: props.content)
        Text(content)
            .applyFont(props.font)
            .applyTextColor(props.color)
            .applyTextAlignment(props.alignment)
            .lineLimit(props.lineLimit)
            .minimumScaleFactor(props.minimumScaleFactor ?? 1.0)
            .applyNodeStyle(props.style)
    }

    @ViewBuilder
    private func renderSFSymbol(_ props: SFSymbolProperties) -> some View {
        Image(systemName: props.systemName)
            .applySymbolFont(size: props.fontSize, weight: props.fontWeight)
            .applySymbolRendering(props.renderingMode)
            .applyForegroundColor(props.color)
            .applyNodeStyle(props.style)
    }

    @ViewBuilder
    private func renderImage(_ props: ImageProperties) -> some View {
        Group {
            switch props.source {
            case .asset(let name):
                Image(name)
                    .resizable()
            case .remote:
                // Remote images need async loading — placeholder for now
                Image(systemName: "photo")
                    .resizable()
            case .data(let base64):
                #if os(iOS)
                if let data = Data(base64Encoded: base64),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                } else {
                    Image(systemName: "photo")
                        .resizable()
                }
                #else
                Image(systemName: "photo")
                    .resizable()
                #endif
            }
        }
        .applyContentMode(props.contentMode)
        .applyCornerRadius(props.cornerRadius)
        .applyNodeStyle(props.style)
    }

    @ViewBuilder
    private func renderDivider(_ props: DividerProperties?) -> some View {
        if let color = props?.color {
            Divider()
                .overlay(ColorRenderer.resolve(color))
                .frame(height: props?.thickness)
        } else {
            Divider()
        }
    }

    @ViewBuilder
    private func renderGauge(_ props: GaugeProperties) -> some View {
        let minVal = props.minValue ?? 0.0
        let maxVal = props.maxValue ?? 1.0
        Gauge(value: props.value, in: minVal...maxVal) {
            if let label = props.label {
                Text(label)
            }
        } currentValueLabel: {
            if let cvl = props.currentValueLabel {
                Text(context.resolveBindings(in: cvl))
            }
        }
        .applyGaugeStyle(props.gaugeStyle)
        .applyGaugeTint(props.tint)
        .applyNodeStyle(props.style)
    }

    @ViewBuilder
    private func renderFrame(_ props: FrameProperties) -> some View {
        NodeRenderer(node: props.child, context: context)
            .frame(
                minWidth: props.minWidth,
                idealWidth: nil,
                maxWidth: props.maxWidth,
                minHeight: props.minHeight,
                idealHeight: nil,
                maxHeight: props.maxHeight,
                alignment: mapAlignment(props.alignment)
            )
            .frame(width: props.width, height: props.height)
            .applyNodeStyle(props.style)
    }

    @ViewBuilder
    private func renderPadding(_ props: PaddingProperties) -> some View {
        NodeRenderer(node: props.child, context: context)
            .applyPadding(edges: props.edges, value: props.value)
            .applyNodeStyle(props.style)
    }

    @ViewBuilder
    private func renderContainerRelativeShape(_ props: ContainerRelativeShapeProperties?) -> some View {
        ContainerRelativeShape()
            .fill(props?.fill.map { ColorRenderer.resolve($0) } ?? Color.clear)
            .applyNodeStyle(props?.style)
    }

    // MARK: - Alignment Mappers

    private func mapHorizontalAlignment(_ alignment: StackAlignment?) -> HorizontalAlignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        case .center, .none: return .center
        default: return .center
        }
    }

    private func mapVerticalAlignment(_ alignment: StackAlignment?) -> VerticalAlignment {
        switch alignment {
        case .top: return .top
        case .bottom: return .bottom
        case .firstTextBaseline: return .firstTextBaseline
        case .lastTextBaseline: return .lastTextBaseline
        case .center, .none: return .center
        default: return .center
        }
    }

    private func mapAlignment(_ alignment: ZStackAlignment?) -> Alignment {
        switch alignment {
        case .topLeading: return .topLeading
        case .top: return .top
        case .topTrailing: return .topTrailing
        case .leading: return .leading
        case .center, .none: return .center
        case .trailing: return .trailing
        case .bottomLeading: return .bottomLeading
        case .bottom: return .bottom
        case .bottomTrailing: return .bottomTrailing
        }
    }
}
