import Foundation
#if canImport(EventKit)
import EventKit
#endif

// MARK: - Calendar Provider

/// Provides calendar event binding values using EventKit.
/// Returns placeholder values when EventKit is unavailable or access denied.
public struct CalendarProvider: DataProvider {
    public let source: DataSource = .calendar

    public init() {}

    public func fetchValues() async throws -> [String: String] {
        #if canImport(EventKit) && os(iOS)
        let store = EKEventStore()
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            granted = await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { result, _ in
                    continuation.resume(returning: result)
                }
            }
        }

        guard granted else {
            return placeholderValues()
        }

        let now = Date()
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        let predicate = store.predicateForEvents(withStart: now, end: endOfDay, calendars: nil)
        let events = store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        let nextEvent = events.first
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        return [
            "calendar.next.title": nextEvent?.title ?? "No events",
            "calendar.next.time": nextEvent.map { timeFormatter.string(from: $0.startDate) } ?? "--",
            "calendar.next.location": nextEvent?.location ?? "",
            "calendar.count": "\(events.count)",
        ]
        #else
        return placeholderValues()
        #endif
    }

    private func placeholderValues() -> [String: String] {
        [
            "calendar.next.title": "No events",
            "calendar.next.time": "--",
            "calendar.next.location": "",
            "calendar.count": "0",
        ]
    }
}
