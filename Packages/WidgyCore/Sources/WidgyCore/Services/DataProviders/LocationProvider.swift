import Foundation
#if canImport(CoreLocation)
import CoreLocation
#endif
#if canImport(MapKit)
import MapKit
#endif

// MARK: - Location Provider

/// Provides location binding values using CoreLocation and MapKit.
/// Returns placeholder values when location services are unavailable.
public struct LocationProvider: DataProvider {
    public let source: DataSource = .location

    public init() {}

    public func fetchValues() async throws -> [String: String] {
        #if os(iOS)
        let manager = CLLocationManager()
        guard let location = manager.location else {
            return placeholderValues()
        }

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        // Use MapKit MKReverseGeocodingRequest for iOS 26+
        do {
            guard let request = MKReverseGeocodingRequest(location: location) else {
                return coordinateOnlyValues(lat: lat, lon: lon)
            }
            let results = try await request.mapItems
            let placemark = results.first?.placemark

            return [
                "location.city": placemark?.locality ?? "Unknown",
                "location.country": placemark?.country ?? "Unknown",
                "location.latitude": String(format: "%.4f", lat),
                "location.longitude": String(format: "%.4f", lon),
            ]
        } catch {
            return coordinateOnlyValues(lat: lat, lon: lon)
        }
        #else
        return placeholderValues()
        #endif
    }

    #if os(iOS)
    private func coordinateOnlyValues(lat: Double, lon: Double) -> [String: String] {
        [
            "location.city": "Unknown",
            "location.country": "Unknown",
            "location.latitude": String(format: "%.4f", lat),
            "location.longitude": String(format: "%.4f", lon),
        ]
    }
    #endif

    private func placeholderValues() -> [String: String] {
        [
            "location.city": "Unknown",
            "location.country": "Unknown",
            "location.latitude": "0.0000",
            "location.longitude": "0.0000",
        ]
    }
}
