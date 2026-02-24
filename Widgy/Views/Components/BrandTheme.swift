import SwiftUI

/// Widgy brand theme colors and gradients.
enum BrandTheme {
    /// Primary brand gradient (purple → blue)
    static let gradient = LinearGradient(
        colors: [Color(red: 0.44, green: 0.38, blue: 0.99), Color(red: 0.33, green: 0.55, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle background gradient for cards and sections
    static let subtleGradient = LinearGradient(
        colors: [Color.accentColor.opacity(0.08), Color.accentColor.opacity(0.02)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// A primary action button style using the brand gradient.
struct BrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(BrandTheme.gradient)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BrandButtonStyle {
    static var brand: BrandButtonStyle { BrandButtonStyle() }
}
