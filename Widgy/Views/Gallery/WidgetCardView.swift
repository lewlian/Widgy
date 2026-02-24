import SwiftUI
import WidgyCore

// MARK: - Widget Card View

struct WidgetCardView: View {
    let config: WidgetConfig

    var body: some View {
        VStack(spacing: 10) {
            WidgetPreviewChrome(config: config)
                .scaleEffect(scaleFactor)
                .frame(height: scaledHeight)
                .clipped()

            VStack(spacing: 2) {
                Text(config.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(config.family.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
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
