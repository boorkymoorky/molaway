import Foundation

/// A descriptive completion ratio, not a health measurement. Only daily totals persist.
struct ScreenScoreTotals: Codable, Equatable, Sendable {
    var completed = 0
    var opportunities = 0
    static let minimumOpportunities = 3
    var valid: Bool {
        (0...8640).contains(opportunities) && (0...opportunities).contains(completed)
    }
    var percent: Int? {
        guard opportunities >= Self.minimumOpportunities, completed >= 0, completed <= opportunities else { return nil }
        return Int((Double(completed) / Double(opportunities) * 100).rounded())
    }
    static func combining(_ rows: [DailySummary]) -> Self? {
        let scores = rows.compactMap(\.score)
        guard !scores.isEmpty else { return nil }
        return scores.reduce(Self()) {
            Self(completed: $0.completed + $1.completed, opportunities: $0.opportunities + $1.opportunities)
        }
    }
}

/// One opportunity per observed work cycle. Snoozes, retries and early returns leave it open.
/// Pending opportunities are memory-only and are never saved as failures on exit.
struct ScreenScoreCycle {
    private var eligible = false
    private var due = false
    mutating func start(fromBeginning: Bool) { eligible = fromBeginning; due = false }
    mutating func observe(confirmedDue: Bool) {
        // A provisional idle rollback can withdraw a due opportunity.
        due = eligible && confirmedDue
    }
    mutating func resolve(completed: Bool) -> Bool? {
        let result: Bool? = due ? completed : nil
        start(fromBeginning: true)
        return result
    }
}
