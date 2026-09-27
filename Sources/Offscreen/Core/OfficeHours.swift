import Foundation

/// A local wall-clock schedule. Weekdays use Calendar's Sunday=1 convention.
/// Overnight (and equal-time, 24-hour) shifts belong to their starting day.
struct OfficeHours: Codable, Equatable, Sendable {
    var enabled = false
    var weekdays: Set<Int> = [2, 3, 4, 5, 6]
    var startMinute = 9 * 60
    var endMinute = 17 * 60

    static let orderedDays = [2, 3, 4, 5, 6, 7, 1]
    static func dayTitle(_ day: Int) -> String {
        L([1: "Sunday", 2: "Monday", 3: "Tuesday", 4: "Wednesday",
           5: "Thursday", 6: "Friday", 7: "Saturday"][day] ?? "")
    }

    mutating func validate() {
        weekdays = weekdays.intersection(1...7)
        startMinute = min(1439, max(0, startMinute))
        endMinute = min(1439, max(0, endMinute))
    }

    private func boundary(on day: Date, minute: Int, end: Bool = false, calendar: Calendar) -> Date? {
        // Missing DST times move to the next valid time. Repeated starts use
        // the first occurrence; repeated ends use the last occurrence.
        calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0,
                      of: day, matchingPolicy: .nextTime,
                      repeatedTimePolicy: end ? .last : .first, direction: .forward)
    }

    func interval(containing now: Date, calendar: Calendar = .autoupdatingCurrent) -> DateInterval? {
        let today = calendar.startOfDay(for: now)
        for offset in [-1, 0] {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  weekdays.contains(calendar.component(.weekday, from: day)),
                  let start = boundary(on: day, minute: startMinute, calendar: calendar),
                  let endDay = calendar.date(byAdding: .day, value: endMinute <= startMinute ? 1 : 0, to: day),
                  let end = boundary(on: endDay, minute: endMinute, end: true, calendar: calendar),
                  start <= now, now < end else { continue }
            return DateInterval(start: start, end: end)
        }
        return nil
    }

    func isOpen(at now: Date, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        !enabled || interval(containing: now, calendar: calendar) != nil
    }

    /// Strictly after the choice time, including when already inside a shift.
    func nextStart(after now: Date, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        guard enabled, !weekdays.isEmpty else { return nil }
        let today = calendar.startOfDay(for: now)
        for offset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  weekdays.contains(calendar.component(.weekday, from: day)),
                  let start = boundary(on: day, minute: startMinute, calendar: calendar),
                  start > now else { continue }
            return start
        }
        return nil
    }
}
