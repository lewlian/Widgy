import WidgetKit

// MARK: - Widget Reloader

/// Triggers widget timeline reloads when configs are saved/updated.
public enum WidgetReloader {
    private static let widgetKind = "WidgyWidget"

    /// Reload all Widgy widget timelines
    public static func reloadAll() {
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    /// Reload after saving a config
    public static func reloadAfterSave() {
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}
