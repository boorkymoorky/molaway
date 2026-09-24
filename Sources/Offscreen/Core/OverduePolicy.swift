import Foundation

enum OverdueLevel: Int, Comparable {
    case normal, amber, red
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    static func evaluate(enabled: Bool, overdue: Double, snoozes: Int, amberMinutes: Int, redMinutes: Int) -> Self {
        guard enabled, overdue.isFinite else { return .normal }
        if overdue >= Double(redMinutes * 60), snoozes >= 3 { return .red }
        return overdue >= Double(amberMinutes * 60) ? .amber : .normal
    }
}
