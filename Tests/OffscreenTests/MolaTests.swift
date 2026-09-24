import Testing
import Foundation
@testable import Offscreen

@Suite struct MolaTests {
    @Test func closingReminderDoesNotStopTimerOrCompleteBreak() {
        let engine = BreakEngine(timing: TimingConfig(workSeconds: 10, shortBreakSeconds: 5, longBreakEvery: 0, leadTimeSeconds: 0))
        engine.gentleReminders = true
        var reminders = 0
        engine.addListener { if case .reminderDue = $0 { reminders += 1 } }
        engine.advance(by: 10)
        #expect(reminders == 1)
        #expect(engine.phase == .working)
        #expect(engine.activeBreak == nil)
        engine.advance(by: 299)
        #expect(reminders == 1)
        engine.advance(by: 1)
        #expect(reminders == 2)
        #expect(engine.workAccrued == 310)
    }
    @Test func snoozeUsesActiveTimeAndPreservesDueWork() {
        let engine = BreakEngine(timing: TimingConfig(workSeconds: 10, leadTimeSeconds: 0))
        engine.gentleReminders = true
        var reminders = 0
        engine.addListener { if case .reminderDue = $0 { reminders += 1 } }
        engine.advance(by: 10)
        engine.deferReminder(seconds: 60)
        engine.advance(by: 59)
        #expect(reminders == 1)
        engine.advance(by: 1)
        #expect(reminders == 2)
        #expect(engine.timeUntilBreak == -60)
    }
    @Test func interruptedBreakKeepsProgressAndRemainsAutomatic() {
        let engine = BreakEngine(timing: TimingConfig(workSeconds: 1200, leadTimeSeconds: 0))
        engine.gentleReminders = true
        engine.advance(by: 1000)
        engine.startBreakNow()
        engine.advance(by: 3)
        engine.cancelBreakKeepingProgress()
        #expect(engine.phase == .working)
        #expect(engine.workAccrued == 1000)
        engine.advance(by: 1)
        #expect(engine.workAccrued == 1001)
    }
    @Test func twoTimersResetOnlyWhenRestIsLongEnough() {
        let eyes = BreakEngine(timing: AppSettings().eyes)
        let movement = BreakEngine(timing: AppSettings().movement)
        eyes.advance(by: 600); movement.advance(by: 600)
        eyes.accountForNaturalRest(20); movement.accountForNaturalRest(20)
        #expect(eyes.workAccrued == 0)
        #expect(movement.workAccrued == 600)
        eyes.advance(by: 100); movement.advance(by: 100)
        eyes.accountForNaturalRest(120); movement.accountForNaturalRest(120)
        #expect(eyes.workAccrued == 0)
        #expect(movement.workAccrued == 0)
    }
    @Test func initialIdleDoesNotStartButFirstInputDoes() {
        var policy = ActivityAccounting()
        #expect(policy.step(now: 0, idle: 20, video: false, locked: false).state == .starting)
        #expect(policy.step(now: 1, idle: 0, video: false, locked: false).state == .active)
        #expect(policy.step(now: 2, idle: 0, video: false, locked: false).activeSeconds == 1)
    }
    @Test func chromeVideoCountsDespiteLongInputInactivity() {
        var policy = ActivityAccounting()
        _ = policy.step(now: 0, idle: 2000, video: true, locked: false)
        let tick = policy.step(now: 1, idle: 2001, video: true, locked: false)
        #expect(tick.state == .video)
        #expect(tick.activeSeconds == 1)
        #expect(tick.restCredit == 0)
    }
    @Test func pausingVideoDoesNotTurnPreviousViewingIntoRest() {
        var policy = ActivityAccounting()
        _ = policy.step(now: 0, idle: 600, video: true, locked: false)
        var decision = policy.step(now: 1, idle: 601, video: false, locked: false)
        #expect(decision.state == .active)
        #expect(decision.restCredit == 0)
        for second in 2...119 { decision = policy.step(now: Double(second), idle: 600 + Double(second), video: false, locked: false) }
        #expect(decision.state == .active)
        decision = policy.step(now: 120, idle: 720, video: false, locked: false)
        #expect(decision.state == .away)
        #expect(decision.restCredit == 120)
    }
    @Test func awayStopsAndInputAutomaticallyResumes() {
        var policy = ActivityAccounting()
        _ = policy.step(now: 0, idle: 0, video: false, locked: false)
        for second in 1...119 { _ = policy.step(now: Double(second), idle: Double(second), video: false, locked: false) }
        let away = policy.step(now: 120, idle: 120, video: false, locked: false)
        #expect(away.state == .away)
        #expect(away.activeSeconds == 0)
        #expect(away.rollback == 119)
        let back = policy.step(now: 121, idle: 0, video: false, locked: false)
        #expect(back.state == .active)
        #expect(back.activeSeconds == 0)
        #expect(back.restCredit == 121)
        #expect(policy.step(now: 122, idle: 0, video: false, locked: false).activeSeconds == 1)
    }
    @Test func lockedVideoNeverAccruesTime() {
        var policy = ActivityAccounting()
        _ = policy.step(now: 0, idle: 0, video: true, locked: false)
        #expect(policy.step(now: 1, idle: 1, video: true, locked: true).state == .sleeping)
        let sleeping = policy.step(now: 601, idle: 601, video: true, locked: true)
        #expect(sleeping.activeSeconds == 0)
        #expect(sleeping.restCredit == 600)
        let unlocked = policy.step(now: 602, idle: 0, video: false, locked: false)
        #expect(unlocked.activeSeconds == 0)
        #expect(unlocked.restCredit >= 600)
    }
    @Test func manualPauseDoesNotAccrueOrPretendToBeRest() {
        var policy = ActivityAccounting()
        _ = policy.step(now: 0, idle: 0, video: false, locked: false)
        let paused = policy.step(now: 1, idle: 0, video: false, locked: false, paused: true)
        #expect(paused.activeSeconds == 0)
        #expect(paused.restCredit == 0)
        #expect(paused.state == .paused)
        #expect(policy.step(now: 2, idle: 0, video: false, locked: false).activeSeconds == 0)
        #expect(policy.step(now: 3, idle: 0, video: false, locked: false).activeSeconds == 1)
    }
    @Test func unexpectedLongGapIsNotWork() {
        var policy = ActivityAccounting()
        _ = policy.step(now: 0, idle: 0, video: false, locked: false)
        #expect(policy.step(now: 3600, idle: 0, video: false, locked: false).activeSeconds == 0)
        #expect(policy.step(now: 3601, idle: 0, video: false, locked: false).activeSeconds == 1)
    }
    @Test func invalidSensorValueFailsClosed() {
        var policy = ActivityAccounting()
        #expect(policy.step(now: 1, idle: .nan, video: true, locked: false).state == .starting)
        #expect(policy.step(now: 2, idle: -.infinity, video: true, locked: false).activeSeconds == 0)
    }
    @Test func mediaRuleRejectsMusicUnityAndGenericWakeLocks() {
        #expect(ChromeVideoRule.matches(bundleID: "com.google.Chrome", name: "Video Wake Lock", type: "PreventUserIdleDisplaySleep", level: 1))
        #expect(ChromeVideoRule.matches(bundleID: "com.google.Chrome", name: "Playing video", type: "PreventUserIdleDisplaySleep", level: 1))
        #expect(!ChromeVideoRule.matches(bundleID: "com.unity3d.UnityEditor", name: "Video Wake Lock", type: "PreventUserIdleDisplaySleep", level: 1))
        #expect(!ChromeVideoRule.matches(bundleID: "com.google.Chrome", name: "Playing audio", type: "PreventUserIdleDisplaySleep", level: 1))
        #expect(!ChromeVideoRule.matches(bundleID: "com.google.Chrome", name: "Screen Wake Lock", type: "PreventUserIdleDisplaySleep", level: 1))
        #expect(!ChromeVideoRule.matches(bundleID: "com.google.Chrome", name: "Video Wake Lock", type: "PreventUserIdleSystemSleep", level: 1))
        #expect(!ChromeVideoRule.matches(bundleID: "com.google.Chrome", name: "Video Wake Lock", type: "PreventUserIdleDisplaySleep", level: 0))
    }
    @Test func chromeLegacyDisplayAssertionIsRecognized() {
        #expect(ChromeVideoRule.matches(bundleID: "com.google.Chrome", name: "Video Wake Lock", type: "NoDisplaySleepAssertion", level: 1))
    }
    @Test func settingsAreBoundedAndRoundTrip() throws {
        var settings = AppSettings()
        settings.eyeMinutes = -1; settings.movementMinutes = Int.max; settings.idlePauseSeconds = -20
        settings.validate()
        #expect(settings.eyeMinutes == 5)
        #expect(settings.movementMinutes == 180)
        #expect(settings.idlePauseSeconds == 30)
        let copy = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings))
        #expect(settings == copy)
    }
}

@Suite struct SuspensionTests {
    @Test func screenWakingDoesNotOverrideScreenLock() {
        var state = SuspensionState()
        #expect(state.suspend("lock") == true)
        #expect(state.suspend("display") == false)
        #expect(state.resume("display") == nil)
        #expect(state.reasons == ["lock"])
        #expect(state.resume("lock") != nil)
        #expect(state.reasons.isEmpty)
    }
    @Test func duplicateAndOutOfOrderWakeDoesNotResume() {
        var state = SuspensionState()
        #expect(state.resume("system") == nil)
        #expect(state.suspend("system") == true)
        #expect(state.suspend("system") == false)
        #expect(state.resume("display") == nil)
        #expect(state.resume("system") != nil)
        #expect(state.resume("system") == nil)
    }
}
