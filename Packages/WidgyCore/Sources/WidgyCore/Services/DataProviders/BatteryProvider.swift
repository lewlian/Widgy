import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Battery Provider

/// Provides battery level and state binding values.
/// Uses UIDevice on iOS; returns placeholder values on macOS.
public struct BatteryProvider: DataProvider {
    public let source: DataSource = .battery

    public init() {}

    public func fetchValues() async throws -> [String: String] {
        #if os(iOS)
        await MainActor.run {
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
        let level = await MainActor.run {
            UIDevice.current.batteryLevel
        }
        let state = await MainActor.run {
            UIDevice.current.batteryState
        }

        let levelString: String
        if level < 0 {
            // Battery level unknown
            levelString = "--"
        } else {
            levelString = "\(Int(level * 100))"
        }

        let stateString: String
        switch state {
        case .charging: stateString = "charging"
        case .full: stateString = "full"
        case .unplugged: stateString = "unplugged"
        case .unknown: stateString = "unknown"
        @unknown default: stateString = "unknown"
        }

        return [
            "battery.level": levelString,
            "battery.state": stateString,
        ]
        #else
        // macOS fallback for compilation/testing
        return [
            "battery.level": "100",
            "battery.state": "full",
        ]
        #endif
    }
}
