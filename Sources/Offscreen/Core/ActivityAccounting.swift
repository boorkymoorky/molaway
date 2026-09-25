import Foundation

enum ActivityState: String {
    case starting, active, video, away, sleeping, paused, resting
    var title: String {
        switch self {
        case .starting: L("Waiting for activity")
        case .active: L("Tracking automatically")
        case .video: L("Video · timers running")
        case .away: L("Away · paused automatically")
        case .sleeping: L("Screen off · paused")
        case .paused: L("Timers paused")
        case .resting: L("Enjoy your break")
        }
    }
}

struct ActivityDecision {
    var state: ActivityState
    var activeSeconds: Double = 0
    var rollback: Double = 0
    var restCredit: Double = 0
}

struct ActivityAccounting {
    private var lastTime: Double?
    private var lastIdle: Double = 0
    private var provisional: Double = 0
    var unconfirmedSeconds: Double { provisional }
    private var lastVideoTime: Double?
    private var lockStart: Double?
    private var lastState: ActivityState = .starting
    private var started = false

    /// Resume on a fresh sample; a suspension can happen entirely between timer ticks.
    mutating func resumeAfterSuspension() {
        lastTime = nil
        lastState = .starting
        lockStart = nil
        lastIdle = 0
        provisional = 0
    }

    mutating func clearProvisional() { provisional = 0 }

    mutating func step(now: Double, idle: Double, video: Bool, locked: Bool,
                       paused: Bool = false, resting: Bool = false, threshold: Double = 120) -> ActivityDecision {
        guard now.isFinite, idle.isFinite, idle >= 0 else {
            lastTime = nil
            lastState = .starting
            return ActivityDecision(state: .starting)
        }
        let rawDelta = lastTime.map { now - $0 } ?? 0
        let delta = rawDelta >= 0 && rawDelta <= 5 ? rawDelta : 0
        lastTime = now
        var restCredit = lastState == .away ? lastIdle + delta : 0
        if locked {
            if lockStart == nil { lockStart = now }
            lastState = .sleeping
            provisional = 0
            return ActivityDecision(state: .sleeping, restCredit: now - (lockStart ?? now))
        }
        if let start = lockStart {
            restCredit = max(restCredit, now - start)
            lockStart = nil
        }
        if video { lastVideoTime = now }
        let effectiveIdle = video ? 0 : min(idle, lastVideoTime.map { now - $0 } ?? idle)
        if !video && effectiveIdle >= threshold {
            let rollback = provisional
            provisional = 0
            lastIdle = effectiveIdle
            lastState = .away
            return ActivityDecision(state: paused ? .paused : .away, rollback: rollback,
                                    restCredit: max(restCredit, effectiveIdle))
        }
        if paused {
            provisional = 0
            lastIdle = effectiveIdle
            lastState = .paused
            return ActivityDecision(state: .paused, restCredit: restCredit)
        }
        if video || effectiveIdle < 2 { started = true }
        guard started else {
            lastState = .starting
            lastIdle = effectiveIdle
            return ActivityDecision(state: .starting, restCredit: restCredit)
        }
        let counted = !resting && (lastState == .active || lastState == .video) ? delta : 0
        if resting || video || effectiveIdle < lastIdle || effectiveIdle < 1 {
            provisional = 0
        } else {
            provisional += counted
        }
        lastIdle = effectiveIdle
        lastState = video ? .video : .active
        return ActivityDecision(state: lastState, activeSeconds: counted, restCredit: restCredit)
    }
}

enum ChromeVideoRule {
    static func matches(bundleID: String, name: String, type: String, level: Int) -> Bool {
        let allowed = ["com.google.Chrome", "com.google.Chrome.beta", "com.google.Chrome.dev", "com.google.Chrome.canary"]
        let displayTypes = ["PreventUserIdleDisplaySleep", "NoDisplaySleepAssertion"]
        guard allowed.contains(bundleID), displayTypes.contains(type), level > 0 else { return false }
        return ["video wake lock", "playing video"].contains(name.lowercased())
    }
}
