import Foundation

enum DurationInput {
    static func parse(_ text: String, within range: ClosedRange<Int>) -> Int? {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 5, text.allSatisfy({ $0.isASCII && $0.isNumber }),
              let value = Int(text), range.contains(value) else { return nil }
        return value
    }
}

/// Ignore one accidental mouse movement; clicks/keys or sustained movement resume.
struct RestReturnPolicy {
    private var movementStarted: Double?
    mutating func reset() { movementStarted = nil }
    mutating func shouldResume(now: Double, restStarted: Double, idle: Double, deliberateIdle: Double) -> Bool {
        guard now - restStarted > 3 else { return false }
        if deliberateIdle.isFinite && now - deliberateIdle > restStarted + 2 { return true }
        if idle < 1.5 {
            if movementStarted == nil { movementStarted = now }
            return now - (movementStarted ?? now) >= 3
        }
        movementStarted = nil
        return false
    }
}

enum MenuTitle {
    static func make(show: Bool, paused: Bool, countdown: String) -> String {
        show && !paused && !countdown.isEmpty ? " " + countdown : ""
    }
}
