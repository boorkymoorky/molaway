import Foundation
import Testing
@testable import Offscreen

@Suite struct LifecycleTests {
    private func withModel(_ body: (AppContainer) throws -> Void) throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let model = AppContainer(settings: SettingsStore(url: dir.appendingPathComponent("settings.json")),
                                 statistics: StatisticsStore(url: dir.appendingPathComponent("statistics.json")))
        defer { model.stop() }
        try body(model)
    }

    @Test func dueWhileAwayResetsBothAndReturnsWithoutStaleReminder() throws {
        try withModel { model in
            var alerts = 0
            model.showReminder = { alerts += 1 }
            model.eyes.advance(by: 1195); model.movement.advance(by: 2995)
            model.tick(now: 0, idle: 0, deliberateIdle: 0)
            for second in 1...180 { model.tick(now: Double(second), idle: Double(second), deliberateIdle: Double(second)) }
            #expect(model.activity == .away)
            #expect(model.eyes.workAccrued == 0 && model.movement.workAccrued == 0)
            let beforeReturn = alerts
            model.tick(now: 181, idle: 0, deliberateIdle: 0)
            for second in 182...361 { model.tick(now: Double(second), idle: 0, deliberateIdle: 0) }
            #expect(model.activity == .active)
            #expect(model.eyes.timeUntilBreak == 1020)
            #expect(model.movement.timeUntilBreak == 2820)
            #expect(alerts == beforeReturn)
            #expect(model.reminderKinds.isEmpty)
        }
    }

    @Test func continueStartsNewCycleWithoutInventingCompletedBreak() throws {
        try withModel { model in
            model.statistics.setEnabled(true)
            model.eyes.advance(by: 1200); model.movement.advance(by: 700)
            model.tick(now: 0, idle: 0, deliberateIdle: 0)
            model.beginRest(.eyes, now: 0)
            model.tick(now: 1, idle: 1, deliberateIdle: 1)
            model.cancelRest()
            #expect(model.activeRest == nil)
            #expect(model.eyes.timeUntilReminder == 1200)
            #expect(model.movement.workAccrued == 700)
            #expect(model.statistics.days.reduce(0) { $0 + $1.breaks } == 0)
            for second in 2...181 { model.tick(now: Double(second), idle: Double(second), deliberateIdle: Double(second)) }
            model.tick(now: 182, idle: 0, deliberateIdle: 0)
            model.tick(now: 183, idle: 0, deliberateIdle: 0)
            #expect(model.activity == .active)
            #expect(model.eyes.timeUntilBreak == 1199)
            #expect(model.movement.timeUntilBreak == 2999)
        }
    }

    @Test func automaticEarlyReturnShowsDeferralCountdownAndKeepsWorking() throws {
        try withModel { model in
            model.eyes.advance(by: 1200)
            model.tick(now: 0, idle: 0, deliberateIdle: 0)
            model.beginRest(.eyes, now: 0)
            for second in 1...4 { model.tick(now: Double(second), idle: Double(second), deliberateIdle: Double(second)) }
            model.tick(now: 5, idle: 0, deliberateIdle: 0)
            #expect(model.activeRest == nil)
            #expect(model.eyes.timeUntilReminder == 300)
            model.tick(now: 6, idle: 0, deliberateIdle: 0)
            #expect(model.eyes.timeUntilReminder == 299)
            #expect(model.eyes.workAccrued == 1201)
        }
    }

    @Test func completingManualRestDoesNotRollbackUncountedRestFromOtherTimer() throws {
        try withModel { model in
            model.settings.update { $0.movementRestMinutes = 3 }
            model.eyes.advance(by: 1200); model.movement.advance(by: 700)
            model.tick(now: 0, idle: 0, deliberateIdle: 0)
            model.beginRest(.eyes, now: 0)
            for second in 1...20 { model.tick(now: Double(second), idle: Double(second), deliberateIdle: Double(second)) }
            #expect(model.activeRest == nil)
            // Stop just below the movement target: only provisional *work* is removed.
            for second in 21...119 { model.tick(now: Double(second), idle: Double(second), deliberateIdle: Double(second)) }
            model.tick(now: 120, idle: 120, deliberateIdle: 120)
            #expect(model.movement.workAccrued == 700)
            #expect(model.eyes.workAccrued == 0)
        }
    }

    @Test func returnOnCompletionTickCountsCompletedRest() throws {
        try withModel { model in
            model.statistics.setEnabled(true)
            model.eyes.advance(by: 1200)
            model.tick(now: 0, idle: 0, deliberateIdle: 0)
            model.beginRest(.eyes, now: 0)
            for second in 1...19 { model.tick(now: Double(second), idle: Double(second), deliberateIdle: Double(second)) }
            model.tick(now: 20, idle: 0, deliberateIdle: 0)
            #expect(model.activeRest == nil)
            #expect(model.eyes.workAccrued == 0)
            #expect(model.statistics.days.reduce(0) { $0 + $1.eyes } == 1)
        }
    }

    @Test func sleepWithoutAnIntermediateTickClearsQueuedDueReminder() throws {
        try withModel { model in
            var alerts = 0
            model.showReminder = { alerts += 1 }
            model.eyes.advance(by: 1200)
            model.suspendTracking()
            model.resumeTracking(after: 180)
            model.tick(now: 180, idle: 0, deliberateIdle: 0)
            model.tick(now: 181, idle: 0, deliberateIdle: 0)
            #expect(alerts == 0)
            #expect(model.eyes.timeUntilBreak > 1198)
            #expect(model.reminderKinds.isEmpty)
        }
    }

    @Test func sleepingDuringManualRestCannotLeaveTheEngineInBreak() throws {
        try withModel { model in
            model.eyes.advance(by: 1200)
            model.beginRest(.eyes, now: 0)
            model.suspendTracking()
            model.resumeTracking(after: 180)
            model.tick(now: 180, idle: 0, deliberateIdle: 0)
            model.tick(now: 181, idle: 0, deliberateIdle: 0)
            #expect(model.activeRest == nil)
            #expect(model.eyes.phase == .working)
            #expect(model.eyes.timeUntilBreak == 1199)
        }
    }

    @Test func snoozedEyeReminderIsClearedByCompletedManualRest() throws {
        try withModel { model in
            model.eyes.advance(by: 1200)
            model.tick(now: 0, idle: 0, deliberateIdle: 0)
            model.snoozeReminder()
            #expect(model.eyes.timeUntilReminder == 300)
            model.beginRest(.eyes, now: 0)
            for second in 1...20 { model.tick(now: Double(second), idle: Double(second), deliberateIdle: Double(second)) }
            #expect(model.eyes.timeUntilReminder == 1200)
            var alerts = 0; model.showReminder = { alerts += 1 }
            for second in 21...321 { model.tick(now: Double(second), idle: 0, deliberateIdle: 0) }
            #expect(alerts == 0)
            #expect(model.eyes.timeUntilReminder > 890)
        }
    }

    @Test func snoozedRemindersAreClearedByLongNaturalAbsence() throws {
        try withModel { model in
            model.eyes.advance(by: 1200); model.movement.advance(by: 3000)
            model.tick(now: 0, idle: 0, deliberateIdle: 0)
            model.snoozeReminder()
            for second in 1...180 { model.tick(now: Double(second), idle: Double(second), deliberateIdle: Double(second)) }
            model.tick(now: 181, idle: 0, deliberateIdle: 0)
            #expect(model.eyes.timeUntilReminder == 1200)
            #expect(model.movement.timeUntilReminder == 3000)
            var alerts = 0; model.showReminder = { alerts += 1 }
            for second in 182...482 { model.tick(now: Double(second), idle: 0, deliberateIdle: 0) }
            #expect(alerts == 0)
        }
    }

    @Test func shortEyeRestLeavesSeparateMovementReminderDueSoon() throws {
        try withModel { model in
            model.eyes.advance(by: 1200); model.movement.advance(by: 3000)
            model.tick(now: 0, idle: 0, deliberateIdle: 0)
            model.snoozeReminder()
            model.beginRest(.eyes, now: 0)
            for second in 1...20 { model.tick(now: Double(second), idle: Double(second), deliberateIdle: Double(second)) }
            #expect(model.eyes.timeUntilReminder == 1200)
            #expect(model.movement.timeUntilReminder == 300)
            #expect(model.nextKind == .movement)
            #expect(model.nextReadout.kind == .movement)
            #expect(model.nextReadout.seconds == model.readout(for: .movement).seconds)
            #expect(model.nextReadout.clock == "5:00")
            #expect(model.readout(for: .eyes).clock == "20:00")
            #expect(model.nextReadout.menuText.contains(model.nextReadout.kind.shortTitle))
        }
    }

    @Test func manualRestNeverCreatesProvisionalWork() {
        var accounting = ActivityAccounting()
        _ = accounting.step(now: 0, idle: 0, video: false, locked: false)
        for second in 1...119 {
            let d = accounting.step(now: Double(second), idle: Double(second), video: false, locked: false, resting: true)
            #expect(d.activeSeconds == 0)
        }
        #expect(accounting.step(now: 120, idle: 120, video: false, locked: false, resting: true).rollback == 0)
    }
}
