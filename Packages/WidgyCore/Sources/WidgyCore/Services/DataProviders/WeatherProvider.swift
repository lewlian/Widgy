import Foundation
#if canImport(WeatherKit)
import WeatherKit
import CoreLocation
#endif

// MARK: - Weather Provider

/// Provides weather binding values using WeatherKit on iOS.
/// Returns mock data when WeatherKit is unavailable.
public struct WeatherProvider: DataProvider {
    public let source: DataSource = .weather

    public init() {}

    public func fetchValues() async throws -> [String: String] {
        #if canImport(WeatherKit) && os(iOS)
        do {
            let weatherService = WeatherService.shared
            // Default to a generic location if location services unavailable
            let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
            let weather = try await weatherService.weather(for: location)
            let current = weather.currentWeather

            let tempF = current.temperature.converted(to: .fahrenheit).value
            let condition = current.condition.description

            // Get daily forecast for high/low
            let daily = weather.dailyForecast.forecast.first
            let highF = daily?.highTemperature.converted(to: .fahrenheit).value ?? tempF
            let lowF = daily?.lowTemperature.converted(to: .fahrenheit).value ?? tempF

            return [
                "weather.temperature": "\(Int(tempF.rounded()))",
                "weather.condition": condition,
                "weather.high": "\(Int(highF.rounded()))",
                "weather.low": "\(Int(lowF.rounded()))",
                "weather.icon": current.symbolName,
            ]
        } catch {
            return mockWeatherValues()
        }
        #else
        return mockWeatherValues()
        #endif
    }

    private func mockWeatherValues() -> [String: String] {
        [
            "weather.temperature": "72",
            "weather.condition": "Partly Cloudy",
            "weather.high": "78",
            "weather.low": "62",
            "weather.icon": "cloud.sun.fill",
        ]
    }
}
