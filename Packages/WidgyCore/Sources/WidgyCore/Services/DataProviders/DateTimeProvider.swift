import Foundation

// MARK: - Date/Time Provider

/// Provides date and time binding values using pure Foundation APIs.
public struct DateTimeProvider: DataProvider {
    public let source: DataSource = .dateTime

    public init() {}

    public func fetchValues() async throws -> [String: String] {
        let now = Date()
        let calendar = Calendar.current

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"

        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let year = calendar.component(.year, from: now)

        return [
            "date_time.time": timeFormatter.string(from: now),
            "date_time.date": dateFormatter.string(from: now),
            "date_time.hour": "\(hour)",
            "date_time.minute": String(format: "%02d", minute),
            "date_time.weekday": weekdayFormatter.string(from: now),
            "date_time.month": monthFormatter.string(from: now),
            "date_time.year": "\(year)",
        ]
    }
}
