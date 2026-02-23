import SwiftUI

// MARK: - Widget Config Renderer

/// Top-level renderer that validates a config, then renders it.
/// Use this as the entry point for rendering a complete widget config.
public struct WidgetConfigRenderer: View {
    let config: WidgetConfig
    let context: RenderContext
    let showErrors: Bool

    public init(
        config: WidgetConfig,
        context: RenderContext = .default,
        showErrors: Bool = false
    ) {
        self.config = config
        self.context = context
        self.showErrors = showErrors
    }

    public var body: some View {
        let result = ConfigValidator().validate(config)

        if result.isValid || !showErrors {
            NodeRenderer(node: config.root, context: context)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.orange)
                ForEach(Array(result.errors.prefix(3).enumerated()), id: \.offset) { _, error in
                    Text(error.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
    }
}
