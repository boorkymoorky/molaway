import Foundation

/// Coalesces reminders during meetings/presentations and a quiet return period.
struct ReminderPolicy {
    private(set) var held = false
    private(set) var releaseAt: Double?
    private(set) var pending = Set<MolaKind>()
    mutating func update(now: Double, suppressed: Bool, eligible: Bool, due: Set<MolaKind>) -> Set<MolaKind> {
        pending.formUnion(due)
        if suppressed { held = true; releaseAt = nil; return [] }
        if held { held = false; releaseAt = now + 60 }
        guard eligible, releaseAt.map({ now >= $0 }) ?? true else { return [] }
        releaseAt = nil
        let result = pending
        pending.removeAll()
        return result
    }
    mutating func clear(_ kind: MolaKind) { pending.remove(kind) }
    mutating func clearAll() { pending.removeAll(); held = false; releaseAt = nil }
}
