import SwiftUI

// MARK: - Node Style Modifier

extension View {
    @ViewBuilder
    func applyNodeStyle(_ style: NodeStyle?) -> some View {
        if let style {
            self
                .applyBackground(style.background)
                .applyCornerRadius(style.cornerRadius)
                .applyOpacity(style.opacity)
                .applyShadow(style.shadow)
                .applyBorder(style.border, cornerRadius: style.cornerRadius)
                .applyGlassEffect(style.glassEffect)
        } else {
            self
        }
    }

    // MARK: - Background

    @ViewBuilder
    func applyBackground(_ background: BackgroundValue?) -> some View {
        if let background {
            self.background(ColorRenderer.resolveBackground(background))
        } else {
            self
        }
    }

    // MARK: - Corner Radius

    @ViewBuilder
    func applyCornerRadius(_ radius: CGFloat?) -> some View {
        if let radius {
            self.clipShape(RoundedRectangle(cornerRadius: radius))
        } else {
            self
        }
    }

    // MARK: - Opacity

    @ViewBuilder
    func applyOpacity(_ opacity: Double?) -> some View {
        if let opacity {
            self.opacity(opacity)
        } else {
            self
        }
    }

    // MARK: - Shadow

    @ViewBuilder
    func applyShadow(_ shadow: ShadowDescriptor?) -> some View {
        if let shadow {
            let color = shadow.color.map { ColorRenderer.resolve($0) } ?? Color.black.opacity(0.33)
            self.shadow(color: color, radius: shadow.radius, x: shadow.x ?? 0, y: shadow.y ?? 0)
        } else {
            self
        }
    }

    // MARK: - Border

    @ViewBuilder
    func applyBorder(_ border: BorderDescriptor?, cornerRadius: CGFloat?) -> some View {
        if let border {
            let color = ColorRenderer.resolve(border.color)
            if let cr = cornerRadius {
                self.overlay(
                    RoundedRectangle(cornerRadius: cr)
                        .stroke(color, lineWidth: border.width)
                )
            } else {
                self.border(color, width: border.width)
            }
        } else {
            self
        }
    }

    // MARK: - Glass Effect (Liquid Glass)

    @ViewBuilder
    func applyGlassEffect(_ enabled: Bool?) -> some View {
        if enabled == true {
            #if os(iOS)
            self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
            #else
            self.background(.ultraThinMaterial)
            #endif
        } else {
            self
        }
    }

    // MARK: - Font

    @ViewBuilder
    func applyFont(_ font: FontDescriptor?) -> some View {
        if let font {
            let base: Font = {
                if let style = font.style {
                    return mapFontStyle(style)
                } else if let size = font.size {
                    return .system(size: size)
                } else {
                    return .body
                }
            }()

            let weighted = font.weight.map { base.weight(mapFontWeight($0)) } ?? base
            let designed: Font = if let design = font.design {
                switch design {
                case .rounded: weighted.width(.standard)
                case .serif: weighted
                case .monospaced: weighted.monospaced()
                case .default: weighted
                }
            } else {
                weighted
            }

            self.font(designed)
        } else {
            self
        }
    }

    // MARK: - Text Color

    @ViewBuilder
    func applyTextColor(_ color: ColorValue?) -> some View {
        if let color {
            self.foregroundStyle(ColorRenderer.resolve(color))
        } else {
            self
        }
    }

    // MARK: - Text Alignment

    @ViewBuilder
    func applyTextAlignment(_ alignment: TextAlignment?) -> some View {
        switch alignment {
        case .leading:
            self.multilineTextAlignment(.leading)
        case .center:
            self.multilineTextAlignment(.center)
        case .trailing:
            self.multilineTextAlignment(.trailing)
        case .none:
            self
        }
    }

    // MARK: - Symbol

    @ViewBuilder
    func applySymbolFont(size: CGFloat?, weight: FontWeight?) -> some View {
        let fontSize = size ?? 17
        let fontWeight = weight.map { mapFontWeight($0) } ?? .regular
        self.font(.system(size: fontSize, weight: fontWeight))
    }

    @ViewBuilder
    func applySymbolRendering(_ mode: SymbolRenderingMode?) -> some View {
        switch mode {
        case .monochrome:
            self.symbolRenderingMode(.monochrome)
        case .multicolor:
            self.symbolRenderingMode(.multicolor)
        case .hierarchical:
            self.symbolRenderingMode(.hierarchical)
        case .palette:
            self.symbolRenderingMode(.palette)
        case .none:
            self
        }
    }

    @ViewBuilder
    func applyForegroundColor(_ color: ColorValue?) -> some View {
        if let color {
            self.foregroundStyle(ColorRenderer.resolve(color))
        } else {
            self
        }
    }

    // MARK: - Image

    @ViewBuilder
    func applyContentMode(_ mode: ImageContentMode?) -> some View {
        switch mode {
        case .fit:
            self.aspectRatio(contentMode: .fit)
        case .fill:
            self.aspectRatio(contentMode: .fill)
        case .none:
            self.aspectRatio(contentMode: .fit)
        }
    }

    // MARK: - Gauge

    @ViewBuilder
    func applyGaugeStyle(_ style: GaugeStyle?) -> some View {
        switch style {
        case .linear:
            self.gaugeStyle(.linearCapacity)
        case .circular, .accessoryCircular:
            self.gaugeStyle(.accessoryCircularCapacity)
        case .accessoryLinear:
            self.gaugeStyle(.accessoryLinear)
        case .automatic, .none:
            self.gaugeStyle(.automatic)
        }
    }

    @ViewBuilder
    func applyGaugeTint(_ tint: ColorValue?) -> some View {
        if let tint {
            self.tint(ColorRenderer.resolve(tint))
        } else {
            self
        }
    }

    // MARK: - Padding

    @ViewBuilder
    func applyPadding(edges: PaddingEdges?, value: CGFloat?) -> some View {
        let amount = value ?? 16
        switch edges {
        case .all, .none:
            self.padding(amount)
        case .horizontal:
            self.padding(.horizontal, amount)
        case .vertical:
            self.padding(.vertical, amount)
        case .top:
            self.padding(.top, amount)
        case .bottom:
            self.padding(.bottom, amount)
        case .leading:
            self.padding(.leading, amount)
        case .trailing:
            self.padding(.trailing, amount)
        }
    }
}

// MARK: - Font Helpers

private func mapFontStyle(_ style: FontStyle) -> Font {
    switch style {
    case .largeTitle: return .largeTitle
    case .title: return .title
    case .title2: return .title2
    case .title3: return .title3
    case .headline: return .headline
    case .subheadline: return .subheadline
    case .body: return .body
    case .callout: return .callout
    case .footnote: return .footnote
    case .caption: return .caption
    case .caption2: return .caption2
    }
}

private func mapFontWeight(_ weight: FontWeight) -> Font.Weight {
    switch weight {
    case .ultraLight: return .ultraLight
    case .thin: return .thin
    case .light: return .light
    case .regular: return .regular
    case .medium: return .medium
    case .semibold: return .semibold
    case .bold: return .bold
    case .heavy: return .heavy
    case .black: return .black
    }
}
