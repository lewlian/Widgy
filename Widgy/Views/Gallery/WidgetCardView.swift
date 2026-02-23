import SwiftUI
import WidgyCore

// MARK: - Widget Card View

struct WidgetCardView: View {
    let config: WidgetConfig

    var body: some View {
        VStack(spacing: 8) {
            WidgetPreviewChrome(config: config)
                .scaleEffect(scaleFactor)
                .frame(height: scaledHeight)

            Text(config.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(config.family.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }

    // Scale down to fit in a grid cell
    private var scaleFactor: CGFloat {
        switch config.family {
        case .systemSmall: return 0.45
        case .systemMedium: return 0.4
        case .systemLarge: return 0.35
        default: return 0.5
        }
    }

    private var scaledHeight: CGFloat {
        switch config.family {
        case .systemSmall: return 100
        case .systemMedium: return 90
        case .systemLarge: return 150
        default: return 60
        }
    }
}

#Preview {
    WidgetCardView(config: SampleConfigs.simpleClock)
        .frame(width: 180)
}
