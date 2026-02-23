import Foundation

// MARK: - Sample Configs for Testing

public enum SampleConfigs {
    /// A simple clock widget
    public static let simpleClock = WidgetConfig(
        name: "Simple Clock",
        description: "A clean time display widget",
        family: .systemSmall,
        root: .vStack(StackProperties(
            children: [
                .text(TextProperties(
                    content: "{{date_time.time}}",
                    font: FontDescriptor(style: .largeTitle, weight: .bold, design: .rounded),
                    color: .semantic(.primary),
                    alignment: .center
                )),
                .text(TextProperties(
                    content: "{{date_time.date}}",
                    font: FontDescriptor(style: .caption, weight: .medium),
                    color: .semantic(.secondaryLabel),
                    alignment: .center
                ))
            ],
            alignment: .center,
            spacing: 4
        ))
    )

    /// A weather overview widget
    public static let weatherWidget = WidgetConfig(
        name: "Weather Overview",
        description: "Current temperature and conditions",
        family: .systemSmall,
        root: .vStack(StackProperties(
            children: [
                .hStack(StackProperties(
                    children: [
                        .sfSymbol(SFSymbolProperties(
                            systemName: "sun.max.fill",
                            color: .system(.yellow),
                            fontSize: 32,
                            renderingMode: .multicolor
                        )),
                        .spacer(nil)
                    ]
                )),
                .spacer(nil),
                .text(TextProperties(
                    content: "{{weather.temperature}}",
                    font: FontDescriptor(style: .largeTitle, weight: .bold),
                    color: .semantic(.primary)
                )),
                .text(TextProperties(
                    content: "{{weather.condition}}",
                    font: FontDescriptor(style: .subheadline),
                    color: .semantic(.secondaryLabel)
                ))
            ],
            alignment: .leading,
            spacing: 4,
            style: NodeStyle(glassEffect: true)
        ))
    )

    /// A battery gauge widget
    public static let batteryWidget = WidgetConfig(
        name: "Battery Level",
        description: "Battery percentage with gauge",
        family: .systemSmall,
        root: .vStack(StackProperties(
            children: [
                .hStack(StackProperties(
                    children: [
                        .sfSymbol(SFSymbolProperties(
                            systemName: "battery.75percent",
                            color: .system(.green),
                            fontSize: 20
                        )),
                        .text(TextProperties(
                            content: "Battery",
                            font: FontDescriptor(style: .headline, weight: .semibold),
                            color: .semantic(.primary)
                        ))
                    ],
                    spacing: 6
                )),
                .spacer(nil),
                .gauge(GaugeProperties(
                    value: 0.75,
                    label: "Battery",
                    currentValueLabel: "75%",
                    gaugeStyle: .linear,
                    tint: .system(.green)
                )),
                .text(TextProperties(
                    content: "{{battery.level}}",
                    font: FontDescriptor(style: .title, weight: .bold),
                    color: .semantic(.primary),
                    alignment: .center
                ))
            ],
            alignment: .leading,
            spacing: 8
        ))
    )

    /// All sample configs
    public static let all: [WidgetConfig] = [simpleClock, weatherWidget, batteryWidget]
}
