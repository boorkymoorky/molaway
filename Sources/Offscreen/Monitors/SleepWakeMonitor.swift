// Adapted from Offscreen's sleep/wake monitor. Track overlapping suspension reasons.
import AppKit

struct SuspensionState {
    private(set) var reasons: Set<String> = []
    private var started: ContinuousClock.Instant?
    mutating func suspend(_ reason: String) -> Bool {
        let first = reasons.isEmpty
        reasons.insert(reason)
        if first { started = .now }
        return first
    }
    mutating func resume(_ reason: String) -> Double? {
        guard reasons.remove(reason) != nil, reasons.isEmpty, let started else { return nil }
        self.started = nil
        return started.duration(to: .now).seconds
    }
}

final class SleepWakeMonitor {
    private var state = SuspensionState()
    private var tokens: [(NotificationCenter, NSObjectProtocol)] = []
    private let onSuspend: () -> Void
    private let onResume: (TimeInterval) -> Void

    init(onSuspend: @escaping () -> Void, onResume: @escaping (TimeInterval) -> Void) {
        self.onSuspend = onSuspend
        self.onResume = onResume
        let workspace = NSWorkspace.shared.notificationCenter
        pair(workspace, NSWorkspace.willSleepNotification, NSWorkspace.didWakeNotification, "system")
        pair(workspace, NSWorkspace.screensDidSleepNotification, NSWorkspace.screensDidWakeNotification, "display")
        pair(workspace, NSWorkspace.sessionDidResignActiveNotification, NSWorkspace.sessionDidBecomeActiveNotification, "session")
        let distributed = DistributedNotificationCenter.default()
        pair(distributed, .init("com.apple.screenIsLocked"), .init("com.apple.screenIsUnlocked"), "lock")
        pair(distributed, .init("com.apple.screensaver.didstart"), .init("com.apple.screensaver.didstop"), "saver")
    }
    func stop() { for (center, token) in tokens { center.removeObserver(token) }; tokens.removeAll() }
    private func pair(_ center: NotificationCenter, _ off: Notification.Name, _ on: Notification.Name, _ reason: String) {
        tokens.append((center, center.addObserver(forName: off, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.state.suspend(reason) { self.onSuspend() }
            }
        }))
        tokens.append((center, center.addObserver(forName: on, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if let gap = self.state.resume(reason) { self.onResume(gap) }
            }
        }))
    }
}
