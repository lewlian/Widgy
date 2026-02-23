import SwiftUI

// MARK: - Color Renderer

/// Resolves ColorValue from the config schema into SwiftUI Color instances.
public enum ColorRenderer {

    public static func resolve(_ colorValue: ColorValue) -> Color {
        switch colorValue {
        case .hex(let hex):
            return colorFromHex(hex)
        case .system(let systemColor):
            return resolveSystem(systemColor)
        case .semantic(let semanticColor):
            return resolveSemantic(semanticColor)
        }
    }

    // MARK: - Hex

    private static func colorFromHex(_ hex: String) -> Color {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        switch cleaned.count {
        case 3: // RGB shorthand
            let r = Double((rgb >> 8) & 0xF) / 15.0
            let g = Double((rgb >> 4) & 0xF) / 15.0
            let b = Double(rgb & 0xF) / 15.0
            return Color(red: r, green: g, blue: b)
        case 4: // RGBA shorthand
            let r = Double((rgb >> 12) & 0xF) / 15.0
            let g = Double((rgb >> 8) & 0xF) / 15.0
            let b = Double((rgb >> 4) & 0xF) / 15.0
            let a = Double(rgb & 0xF) / 15.0
            return Color(red: r, green: g, blue: b, opacity: a)
        case 6: // RRGGBB
            let r = Double((rgb >> 16) & 0xFF) / 255.0
            let g = Double((rgb >> 8) & 0xFF) / 255.0
            let b = Double(rgb & 0xFF) / 255.0
            return Color(red: r, green: g, blue: b)
        case 8: // RRGGBBAA
            let r = Double((rgb >> 24) & 0xFF) / 255.0
            let g = Double((rgb >> 16) & 0xFF) / 255.0
            let b = Double((rgb >> 8) & 0xFF) / 255.0
            let a = Double(rgb & 0xFF) / 255.0
            return Color(red: r, green: g, blue: b, opacity: a)
        default:
            return .clear
        }
    }

    // MARK: - System Colors

    private static func resolveSystem(_ color: SystemColor) -> Color {
        switch color {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        case .white: return .white
        case .black: return .black
        case .gray: return .gray
        case .clear: return .clear
        }
    }

    // MARK: - Semantic Colors

    private static func resolveSemantic(_ color: SemanticColor) -> Color {
        switch color {
        case .primary: return .primary
        case .secondary: return .secondary
        case .accent: return .accentColor
        #if os(iOS)
        case .label: return Color(UIColor.label)
        case .secondaryLabel: return Color(UIColor.secondaryLabel)
        case .tertiaryLabel: return Color(UIColor.tertiaryLabel)
        case .systemBackground: return Color(UIColor.systemBackground)
        case .secondarySystemBackground: return Color(UIColor.secondarySystemBackground)
        case .separator: return Color(UIColor.separator)
        #else
        case .label: return .primary
        case .secondaryLabel: return .secondary
        case .tertiaryLabel: return .gray
        case .systemBackground: return Color(nsColor: .windowBackgroundColor)
        case .secondarySystemBackground: return Color(nsColor: .controlBackgroundColor)
        case .separator: return Color(nsColor: .separatorColor)
        #endif
        }
    }

    // MARK: - Background

    public static func resolveBackground(_ background: BackgroundValue) -> AnyShapeStyle {
        switch background {
        case .color(let colorValue):
            return AnyShapeStyle(resolve(colorValue))
        case .gradient(let descriptor):
            return resolveGradient(descriptor)
        }
    }

    private static func resolveGradient(_ descriptor: GradientDescriptor) -> AnyShapeStyle {
        let colors = descriptor.colors.map { resolve($0) }
        let start = UnitPoint(
            x: descriptor.startPoint?.x ?? 0.5,
            y: descriptor.startPoint?.y ?? 0
        )
        let end = UnitPoint(
            x: descriptor.endPoint?.x ?? 0.5,
            y: descriptor.endPoint?.y ?? 1
        )

        switch descriptor.type {
        case .linear:
            return AnyShapeStyle(LinearGradient(colors: colors, startPoint: start, endPoint: end))
        case .radial:
            return AnyShapeStyle(RadialGradient(
                colors: colors,
                center: start,
                startRadius: 0,
                endRadius: 200
            ))
        case .angular:
            return AnyShapeStyle(AngularGradient(colors: colors, center: start))
        }
    }
}
