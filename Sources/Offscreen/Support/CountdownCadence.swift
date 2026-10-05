import Foundation

/// Rephase the existing one-second poll; no second timer or display-only clock.
enum CountdownCadence {
    static func delay(remaining: Double, counting: Bool, sampleAge: Double = 0) -> TimeInterval {
        guard counting, remaining.isFinite, remaining > 0,
              sampleAge.isFinite, sampleAge >= 0 else { return 1 }
        // Format.clock rounds up. An integer countdown changes one second later;
        // a fractional countdown changes when its fractional part has elapsed.
        let fraction = remaining.truncatingRemainder(dividingBy: 1)
        let untilBoundary = fraction == 0 ? 1 : fraction
        // Fire just after the boundary, so permitted late delivery cannot straddle
        // both sides of it. Retain Poll's energy-saving tolerance and real deltas.
        // Subtract processing time; bound recovery after a genuine main-loop stall.
        return max(0.05, min(1.05, untilBoundary + 0.05 - sampleAge))
    }
}
