import Foundation
import Testing
@testable import Offscreen

@Suite struct SmartPauseTests {
    @Test func activityAndQuietSignalsRemainIndependent() {
        for videoEnabled in [false, true] {
            for cameraEnabled in [false, true] {
                for focusEnabled in [false, true] {
                    for playing in [false, true] {
                        for watching in [false, true] {
                            for presenting in [false, true] {
                                for camera in [nil, false, true] as [Bool?] {
                                    for focus in [nil, false, true] as [Bool?] {
                                        var config = AppSettings()
                                        config.videoEnabled = videoEnabled
                                        config.cameraSuppression = cameraEnabled
                                        config.focusSuppression = focusEnabled
                                        let result = SmartPause(config: config, videoPlaying: playing, watching: watching,
                                            cameraActive: camera, focusActive: focus, presenting: presenting)
                                        #expect(result.keepsCounting == ((videoEnabled && playing) || watching || (cameraEnabled && camera == true)))
                                        #expect(result.quietReasons.contains(.presentation) == presenting)
                                        #expect(result.quietReasons.contains(.camera) == (cameraEnabled && camera == true))
                                        #expect(result.quietReasons.contains(.focus) == (focusEnabled && focus == true))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @Test func watchingOverridesIdleButFocusDoesNotInventActivity() {
        var config = AppSettings(); config.videoEnabled = false; config.focusSuppression = true
        let watching = SmartPause(config: config, videoPlaying: false, watching: true,
            cameraActive: nil, focusActive: nil, presenting: false)
        var accounting = ActivityAccounting()
        #expect(accounting.step(now: 0, idle: 300, video: watching.keepsCounting, locked: false).state == .video)
        #expect(accounting.step(now: 1, idle: 301, video: watching.keepsCounting, locked: false).activeSeconds == 1)
        let focus = SmartPause(config: config, videoPlaying: false, watching: false,
            cameraActive: nil, focusActive: true, presenting: false)
        #expect(!focus.keepsCounting && focus.quietReasons == [.focus])
        #expect(accounting.step(now: 2, idle: 302, video: false, locked: true).activeSeconds == 0)
        #expect(accounting.step(now: 3, idle: 0, video: true, locked: false, paused: true).activeSeconds == 0)
    }

    @Test func continuousTypingHasOneBudgetIncludingRetriesAndSnoozes() {
        var policy = TypingDeferral()
        for second in 0..<30 {
            #expect(policy.update(now: Double(second), cycleDue: true, pending: true, eligible: true,
                enabled: true, keyboardIdle: 0) == Double(30 - second))
        }
        for second in [30.0, 31, 300, 600] {
            #expect(policy.update(now: second, cycleDue: true, pending: true, eligible: true,
                enabled: true, keyboardIdle: 0) == nil)
        }
        #expect(policy.update(now: 601, cycleDue: false, pending: false, eligible: true, enabled: true, keyboardIdle: 0) == nil)
        #expect(policy.update(now: 602, cycleDue: true, pending: true, eligible: true, enabled: true, keyboardIdle: 0) == 30)
    }

    @Test func twoSecondTypingPauseReleasesWithoutASecondBudget() {
        var policy = TypingDeferral()
        #expect(policy.update(now: 10, cycleDue: true, pending: true, eligible: true, enabled: true, keyboardIdle: 1.99) == 30)
        #expect(policy.update(now: 11, cycleDue: true, pending: true, eligible: true, enabled: true, keyboardIdle: 2) == nil)
        #expect(policy.update(now: 12, cycleDue: true, pending: true, eligible: true, enabled: true, keyboardIdle: 0) == nil)
    }

    @Test func missingInvalidAndStaleKeyboardTimingNeverHolds() {
        for idle in [nil, -.infinity, .infinity, .nan, -1, 2, 1000] as [Double?] {
            var policy = TypingDeferral()
            #expect(policy.update(now: 0, cycleDue: true, pending: true, eligible: true, enabled: true, keyboardIdle: idle) == nil)
            #expect(policy.update(now: 1, cycleDue: true, pending: true, eligible: true, enabled: true, keyboardIdle: 0) == nil)
        }
    }

    @Test func quietPauseAndPreviewCannotRefreshTheDeadline() {
        var policy = TypingDeferral()
        #expect(policy.update(now: 0, cycleDue: true, pending: true, eligible: false, enabled: true, keyboardIdle: 0) == nil)
        #expect(policy.update(now: 60, cycleDue: true, pending: true, eligible: true, enabled: true, keyboardIdle: 0) == 30)
        #expect(policy.update(now: 70, cycleDue: true, pending: true, eligible: false, enabled: true, keyboardIdle: 0) == nil)
        #expect(policy.update(now: 91, cycleDue: true, pending: true, eligible: true, enabled: true, keyboardIdle: 0) == nil)
    }

    @Test func disablingOrBackwardClockReleasesAndConsumesAnActiveBudget() {
        for invalidClock in [false, true] {
            var policy = TypingDeferral()
            #expect(policy.update(now: 10, cycleDue: true, pending: true, eligible: true, enabled: true, keyboardIdle: 0) == 30)
            #expect(policy.update(now: invalidClock ? 9 : 11, cycleDue: true, pending: true, eligible: true,
                enabled: invalidClock, keyboardIdle: 0) == nil)
            #expect(policy.update(now: 12, cycleDue: true, pending: true, eligible: true, enabled: true, keyboardIdle: 0) == nil)
        }
    }

    @Test func noPendingReminderDoesNotStartTheBudget() {
        var policy = TypingDeferral()
        #expect(policy.update(now: 0, cycleDue: true, pending: false, eligible: true, enabled: true, keyboardIdle: 0) == nil)
        #expect(policy.update(now: 300, cycleDue: true, pending: true, eligible: true, enabled: true, keyboardIdle: 0) == 30)
    }

    @Test func preferenceIsOptionalOffByDefaultAndRoundTrips() throws {
        #expect(!AppSettings().typingDeferralEnabled)
        #expect(try !SettingsCodec.decode(Data("{}".utf8), strict: true).typingDeferralEnabled)
        var settings = AppSettings(); settings.typingDeferralEnabled = true
        #expect(try SettingsCodec.decode(SettingsCodec.export(settings), strict: true).typingDeferralEnabled)
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(settings)) as? [String: Any])
        object.removeValue(forKey: "typingDeferralEnabled")
        #expect(try !SettingsCodec.decode(JSONSerialization.data(withJSONObject: object), strict: true).typingDeferralEnabled)
        object["typingDeferralEnabled"] = "true"
        #expect(throws: (any Error).self) { try SettingsCodec.decode(JSONSerialization.data(withJSONObject: object), strict: true) }
    }

    private func withModel(long: Bool = false, _ body: (AppContainer) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settings = SettingsStore(url: directory.appendingPathComponent("settings.json"))
        settings.update { $0.videoEnabled = false; $0.typingDeferralEnabled = true; $0.cycleShortCount = long ? $0.shortBreaksBeforeLong : 0 }
        let model = AppContainer(settings: settings, statistics: StatisticsStore(url: directory.appendingPathComponent("stats.json")))
        defer { model.stop() }
        model.tick(now: 0, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
        model.breakEngine.advance(by: 1200)
        try body(model)
    }

    @Test func realCoordinatorHoldsThenDeliversExactlyOnceWithoutCrediting() throws {
        try withModel { model in
            var shown = 0; model.showReminder = { shown += 1 }
            for second in 1...30 {
                model.tick(now: Double(second), idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
                #expect(model.typingDeferred && shown == 0)
            }
            #expect(model.nextReadout.seconds == 1)
            model.tick(now: 31, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            #expect(!model.typingDeferred && shown == 1)
            #expect(model.reminderKinds == [.short])
            #expect(model.breakEngine.workAccrued == 1231)
            #expect(model.breakEngine.shortBreaksSinceLong == 0 && model.breakEngine.explicitDeferrals == 0)
            model.tick(now: 32, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            #expect(shown == 1)
            model.dismissReminder()
            model.breakEngine.advance(by: 300)
            model.tick(now: 333, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            #expect(shown == 2 && !model.typingDeferred)
        }
    }

    @Test func fallbackAndOptOutDeliverNormally() throws {
        for enabled in [false, true] {
            try withModel { model in
                model.settings.update { $0.typingDeferralEnabled = enabled }
                var shown = 0; model.showReminder = { shown += 1 }
                model.tick(now: 1, idle: 0, deliberateIdle: .infinity, keyboardIdle: enabled ? nil : 0)
                #expect(shown == 1 && !model.typingDeferred)
            }
        }
    }

    @Test func typingPauseAndCompletedRestAllowTheNextCycle() throws {
        try withModel { model in
            var shown = 0; model.showReminder = { shown += 1 }
            model.tick(now: 1, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            model.tick(now: 2, idle: 0, deliberateIdle: .infinity, keyboardIdle: 2)
            #expect(shown == 1 && !model.typingDeferred)
            model.beginRest(.short, now: 2)
            #expect(model.activeRest == .short && !model.typingDeferred)
            model.breakEngine.advance(by: 20)
            #expect(model.activeRest == nil && model.breakEngine.shortBreaksSinceLong == 1)
            model.breakEngine.advance(by: 1200)
            model.tick(now: 3, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            #expect(model.typingDeferred && shown == 2) // only reminder + manual rest
        }
    }

    @Test func previewDoesNotConsumePendingRealReminderOrCreditABreak() throws {
        try withModel { model in
            var realShown = 0; model.showReminder = { if !model.isPreview { realShown += 1 } }
            model.tick(now: 1, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            model.previewReminder()
            model.tick(now: 2, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            #expect(model.isPreview && realShown == 0 && !model.typingDeferred)
            model.dismissReminder()
            model.tick(now: 31, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            #expect(realShown == 1 && !model.isPreview)
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
        }
    }

    @Test func manualPauseAndSleepClearVisibleTypingHold() throws {
        try withModel { model in
            model.tick(now: 1, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            model.suspendTracking()
            #expect(!model.typingDeferred && !model.canPresent)
            model.resumeTracking(after: 0)
            model.pauseTracking(.untilResumed)
            #expect(!model.typingDeferred && !model.canPresent && model.isPaused)
        }
    }

    @Test func allModesAndReminderStylesUseTheSameBoundedGate() throws {
        for mode in DifficultyMode.allCases {
            for style in ReminderStyle.allCases {
                try withModel { model in
                    model.settings.update { $0.skipMode = mode; $0.reminderStyle = style }
                    var shown = 0; model.showReminder = { shown += 1 }
                    model.tick(now: 1, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
                    #expect(model.typingDeferred && !model.canPresent && shown == 0)
                    model.tick(now: 31, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
                    #expect(!model.typingDeferred && model.canPresent && shown == 1)
                    #expect(model.skipCountdown == (mode == .hardcore ? nil : mode == .balanced ? 5 : 0))
                }
            }
        }
    }

    @Test func longBreakHoldKeepsCadenceAndSnoozeCounts() throws {
        try withModel(long: true) { model in
            #expect(model.nextKind == .long)
            model.tick(now: 1, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            #expect(model.typingDeferred && model.nextReadout.kind == .long)
            model.tick(now: 31, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            #expect(model.reminderKinds == [.long])
            model.snoozeReminder()
            #expect(model.breakEngine.explicitDeferrals == 1)
            #expect(model.breakEngine.shortBreaksSinceLong == model.config.shortBreaksBeforeLong)
            model.breakEngine.advance(by: 300)
            model.tick(now: 332, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            #expect(!model.typingDeferred && model.reminderKinds == [.long])
        }
    }
}
