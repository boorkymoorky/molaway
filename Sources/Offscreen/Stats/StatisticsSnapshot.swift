import Foundation

/// Prepared when daily data or locale changes, never inside each chart mark.
struct StatisticsSnapshot {
    let keys: [String]
    let rows: [DailySummary]
    let byDay: [String: DailySummary]
    let labels: [String: String]
    let axisKeys: [String]
    let totals: DailySummary
    let comparison: StatisticsComparison?
    let score: ScreenScoreTotals?

    init(days: [DailySummary], period: Int, today: String, language: String) {
        keys = StatsCalendar.recent(period, today: today)
        let included = Set(keys)
        rows = days.filter { included.contains($0.day) }
        byDay = Dictionary(rows.map { ($0.day, $0) }, uniquingKeysWith: { first, _ in first })
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.setLocalizedDateFormatFromTemplate("dMMM")
        labels = Dictionary(uniqueKeysWithValues: keys.map { key in
            (key, StatsCalendar.date(key).map { formatter.string(from: $0) } ?? key)
        })
        let stride = period == 7 ? 1 : period == 30 ? 7 : 15
        axisKeys = keys.enumerated().filter { $0.offset % stride == 0 }.map(\.element)
        totals = rows.reduce(into: DailySummary(day: today)) { sum, row in
            sum.active += row.active; sum.rest += row.rest; sum.breaks += row.breaks
            sum.eyes += row.eyes; sum.movement += row.movement; sum.shortBreaks += row.shortBreaks; sum.longBreaks += row.longBreaks; sum.natural += row.natural
            sum.video += row.video; sum.watching += row.watching
        }
        score = ScreenScoreTotals.combining(rows)
        comparison = StatisticsComparison.make(days: days, period: period, today: today)
    }
}
