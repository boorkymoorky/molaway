import Foundation

enum CursorCountdownPolicy {
    static let windowSeconds = 10

    static func seconds(remaining: Double, enabled: Bool, eligible: Bool) -> Int? {
        guard enabled, eligible, remaining.isFinite,
              remaining > 0, remaining <= Double(windowSeconds) else { return nil }
        return max(1, Int(ceil(remaining)))
    }
}
