import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

// MARK: - Health Provider

/// Provides health data binding values using HealthKit.
/// Returns placeholder values when HealthKit is unavailable.
public struct HealthProvider: DataProvider {
    public let source: DataSource = .health

    public init() {}

    public func fetchValues() async throws -> [String: String] {
        #if canImport(HealthKit) && os(iOS)
        guard HKHealthStore.isHealthDataAvailable() else {
            return placeholderValues()
        }

        let store = HKHealthStore()
        let stepType = HKQuantityType(.stepCount)
        let distanceType = HKQuantityType(.distanceWalkingRunning)
        let caloriesType = HKQuantityType(.activeEnergyBurned)

        let typesToRead: Set<HKSampleType> = [stepType, distanceType, caloriesType]

        // Request authorization
        do {
            try await store.requestAuthorization(toShare: [], read: typesToRead)
        } catch {
            return placeholderValues()
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        async let steps = querySum(store: store, type: stepType, start: startOfDay, end: now)
        async let distance = querySum(store: store, type: distanceType, start: startOfDay, end: now)
        async let calories = querySum(store: store, type: caloriesType, start: startOfDay, end: now)

        let stepsVal = await steps
        let distVal = await distance
        let calVal = await calories

        return [
            "health.steps": "\(Int(stepsVal))",
            "health.distance": String(format: "%.1f", distVal / 1609.34), // meters to miles
            "health.calories": "\(Int(calVal))",
        ]
        #else
        return placeholderValues()
        #endif
    }

    #if canImport(HealthKit) && os(iOS)
    private func querySum(store: HKHealthStore, type: HKQuantityType, start: Date, end: Date) async -> Double {
        await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let unit: HKUnit
                switch type {
                case HKQuantityType(.stepCount): unit = .count()
                case HKQuantityType(.distanceWalkingRunning): unit = .meter()
                case HKQuantityType(.activeEnergyBurned): unit = .kilocalorie()
                default: unit = .count()
                }
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
    #endif

    private func placeholderValues() -> [String: String] {
        [
            "health.steps": "0",
            "health.distance": "0.0",
            "health.calories": "0",
        ]
    }
}
