import CoreGraphics
import Foundation

/// Seconds since the user last touched keyboard/mouse, via CGEventSource
/// queries (permission-free; not an event tap). Reported once per second.
final class IdleMonitor {
    private var timer: Timer?
    private let onTick: (Double) -> Void

    init(onTick: @escaping (Double) -> Void) {
        self.onTick = onTick
        timer = Poll.every(1.0) { [weak self] in
            guard let self else { return }
            self.onTick(Self.idleSeconds())
        }
    }

    static func deliberateIdleSeconds() -> Double {
        [.keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel].map {
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0)
        }.min() ?? .infinity
    }
    static func idleSeconds() -> Double {
        // kCGAnyInputEventType is ~0 in CGEventTypes.h. One duration query,
        // including tablet input, instead of ten separate WindowServer queries.
        let anyInput = CGEventType(rawValue: UInt32.max)!
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
    }
    /// Aggregate elapsed time only: no event monitor, key identity or text.
    static func keyboardIdleSeconds() -> Double? {
        let elapsed = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        return elapsed.isFinite && elapsed >= 0 ? elapsed : nil
    }
}
