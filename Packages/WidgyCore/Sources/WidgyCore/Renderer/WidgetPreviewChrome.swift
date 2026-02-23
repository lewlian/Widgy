import SwiftUI

// MARK: - Widget Preview Chrome

/// Wraps a rendered widget config in a preview container that simulates
/// the actual widget appearance at real dimensions on the homescreen.
public struct WidgetPreviewChrome: View {
    let config: WidgetConfig
    let context: RenderContext

    public init(config: WidgetConfig, context: RenderContext = .default) {
        self.config = config
        self.context = context
    }

    public var body: some View {
        NodeRenderer(node: config.root, context: context)
            .frame(width: dimensions.width, height: dimensions.height)
            .padding(widgetPadding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    // MARK: - Widget Dimensions

    /// Actual widget dimensions for each family (iPhone 15 Pro reference)
    private var dimensions: CGSize {
        switch config.family {
        case .systemSmall:
            return CGSize(width: 170, height: 170)
        case .systemMedium:
            return CGSize(width: 364, height: 170)
        case .systemLarge:
            return CGSize(width: 364, height: 382)
        case .accessoryCircular:
            return CGSize(width: 76, height: 76)
        case .accessoryRectangular:
            return CGSize(width: 172, height: 76)
        case .accessoryInline:
            return CGSize(width: 234, height: 26)
        }
    }

    private var widgetPadding: CGFloat {
        switch config.family {
        case .systemSmall, .systemMedium, .systemLarge:
            return 16
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return 4
        }
    }

    private var cornerRadius: CGFloat {
        switch config.family {
        case .systemSmall, .systemMedium, .systemLarge:
            return 24
        case .accessoryCircular:
            return 38
        case .accessoryRectangular:
            return 12
        case .accessoryInline:
            return 8
        }
    }
}

// MARK: - Widget Size Helper

extension WidgetFamily {
    public var displayName: String {
        switch self {
        case .systemSmall: return "Small"
        case .systemMedium: return "Medium"
        case .systemLarge: return "Large"
        case .accessoryCircular: return "Circular"
        case .accessoryRectangular: return "Rectangular"
        case .accessoryInline: return "Inline"
        }
    }

    public var isHomeScreen: Bool {
        switch self {
        case .systemSmall, .systemMedium, .systemLarge: return true
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return false
        }
    }
}

// MARK: - Previews

#Preview("Small Widget") {
    WidgetPreviewChrome(config: SampleConfigs.simpleClock)
        .padding()
}

#Preview("Weather Widget") {
    WidgetPreviewChrome(config: SampleConfigs.weatherWidget)
        .padding()
}

#Preview("Battery Widget") {
    WidgetPreviewChrome(config: SampleConfigs.batteryWidget)
        .padding()
}

#Preview("Medium Widget") {
    let config = WidgetConfig(
        name: "Medium Test",
        family: .systemMedium,
        root: .hStack(StackProperties(
            children: [
                .vStack(StackProperties(
                    children: [
                        .text(TextProperties(
                            content: "Good Morning",
                            font: FontDescriptor(style: .headline, weight: .bold),
                            color: .semantic(.primary)
                        )),
                        .text(TextProperties(
                            content: "February 23, 2026",
                            font: FontDescriptor(style: .subheadline),
                            color: .semantic(.secondaryLabel)
                        )),
                        .spacer(nil)
                    ],
                    alignment: .leading,
                    spacing: 4
                )),
                .spacer(nil),
                .sfSymbol(SFSymbolProperties(
                    systemName: "sun.max.fill",
                    color: .system(.yellow),
                    fontSize: 40,
                    renderingMode: .multicolor
                ))
            ],
            spacing: 12
        ))
    )
    WidgetPreviewChrome(config: config)
        .padding()
}

#Preview("All Sizes") {
    VStack(spacing: 20) {
        ForEach(
            [WidgetFamily.systemSmall, .systemMedium, .systemLarge],
            id: \.rawValue
        ) { family in
            let config = WidgetConfig(
                name: "Test",
                family: family,
                root: SampleConfigs.simpleClock.root
            )
            VStack {
                Text(family.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                WidgetPreviewChrome(config: config)
            }
        }
    }
    .padding()
}
