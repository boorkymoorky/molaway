import Foundation

/// Fractions shared by the menu bar and dashboard rings.
struct RingProgress {
    let outer: Double
    let inner: Double?

    init(workAccrued: Double, workSeconds: Int, restRemaining: Double?, restDuration: Double?,
         completedShorts: Int, shortsBeforeLong: Int) {
        if let restRemaining, let restDuration, restDuration > 0 {
            outer = Self.clamp(1 - restRemaining / restDuration)
        } else {
            outer = Self.clamp(workAccrued / Double(max(1, workSeconds)))
        }
        inner = shortsBeforeLong > 0
            ? Self.clamp(Double(completedShorts) / Double(shortsBeforeLong)) : nil
    }

    private static func clamp(_ value: Double) -> Double {
        value.isFinite ? min(1, max(0, value)) : 0
    }
}
