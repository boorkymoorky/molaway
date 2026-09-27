import Foundation
import Testing
@testable import Offscreen

@Suite struct SkipModeTests {
    private func withModel(_ body: (AppContainer, URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settingsURL = directory.appendingPathComponent("settings.json")
        let model = AppContainer(settings: SettingsStore(url: settingsURL),
            statistics: StatisticsStore(url: directory.appendingPathComponent("stats.json")))
        try body(model, settingsURL)
        model.stop()
    }

    @Test func casualSkipsDueReminderAndRestWithoutCadenceCredit() throws {
        try withModel { model, _ in
            model.settings.update { $0.skipMode = .casual }
            model.breakEngine.advance(by: Double(model.config.timing.workSeconds))
            model.reminderKinds = [.short]
            model.markReminderShown(at: 100)
            #expect(model.canSkipBreak)
            #expect(model.skipBreak(now: 100))
            #expect(model.breakEngine.workAccrued == 0)
            #expect(model.breakEngine.shortBreaksSinceLong == 0)

            model.beginRest(.short, now: 200)
            #expect(model.skipBreak(now: 200))
            #expect(model.activeRest == nil)
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
        }
    }

    @Test func balancedHasVisibleFiveSecondGateForReminderAndRest() throws {
        try withModel { model, _ in
            model.breakEngine.advance(by: Double(model.config.timing.workSeconds))
            model.reminderKinds = [.short]
            model.markReminderShown(at: 100)
            #expect(model.skipCountdown == 5)
            #expect(!model.skipBreak(now: 104.99))
            #expect(model.skipCountdown == 1)
            #expect(model.breakEngine.workAccrued >= Double(model.config.timing.workSeconds))
            #expect(model.skipBreak(now: 105))
            #expect(model.breakEngine.shortBreaksSinceLong == 0)

            model.beginRest(.short, now: 200)
            #expect(model.skipCountdown == 5)
            #expect(!model.skipBreak(now: 204))
            #expect(model.skipBreak(now: 205))
            #expect(model.activeRest == nil)
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
        }
    }

    @Test func hardcoreAndPreviewCannotSkipOrGainCompletionByClosing() throws {
        try withModel { model, _ in
            model.settings.update { $0.skipMode = .hardcore }
            model.breakEngine.advance(by: Double(model.config.timing.workSeconds))
            model.reminderKinds = [.short]
            model.markReminderShown(at: 100)
            #expect(model.skipCountdown == nil)
            #expect(!model.skipBreak(now: 1000))
            model.dismissReminder()
            #expect(model.breakEngine.workAccrued >= Double(model.config.timing.workSeconds))
            #expect(model.breakEngine.shortBreaksSinceLong == 0)

            model.beginRest(.short, now: 200)
            #expect(!model.skipBreak(now: 1000))
            model.dismissReminder()
            #expect(model.activeRest == .short)
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
            model.cancelRest() // automatic early return retains due work without completion
            #expect(model.breakEngine.shortBreaksSinceLong == 0)

            model.previewReminder()
            #expect(model.isPreview)
            #expect(!model.skipBreak(now: 1000))
            model.dismissReminder()
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
        }
    }

    @Test func snoozeCannotTurnDeferralIntoCompletionOrSkip() throws {
        try withModel { model, _ in
            model.settings.update { $0.skipMode = .casual }
            model.breakEngine.advance(by: Double(model.config.timing.workSeconds))
            model.reminderKinds = [.short]
            model.markReminderShown(at: 100)
            model.snoozeReminder()
            #expect(model.breakEngine.isExplicitlyDeferred)
            #expect(!model.skipBreak(now: 1000))
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
        }
    }

    @Test func modePersistsAndChangesTakeEffectDuringRest() throws {
        try withModel { model, url in
            model.beginRest(.short)
            model.settings.update { $0.skipMode = .hardcore }
            #expect(!model.canSkipBreak)
            model.settings.update { $0.skipMode = .casual }
            #expect(model.canSkipBreak)
            model.settings.flush()
            let reopened = SettingsStore(url: url)
            #expect(reopened.settings.skipMode == .casual)
        }
    }

    @Test func skippedLongBreakDoesNotAdvanceCadenceOrClearManualPause() throws {
        try withModel { model, _ in
            model.settings.update { $0.skipMode = .casual; $0.shortBreaksBeforeLong = 2 }
            model.pauseTracking(.untilResumed)
            model.breakEngine.restoreCadence(0)
            for _ in 0..<2 {
                model.beginRest(.short)
                model.breakEngine.advance(by: Double(model.config.shortRestSeconds))
            }
            #expect(model.nextKind == .long)
            model.beginRest(.long, now: 100)
            #expect(model.skipBreak(now: 100))
            #expect(model.nextKind == .long)
            #expect(model.breakEngine.shortBreaksSinceLong == 2)
            #expect(model.isPaused)
            #expect(model.activity == .paused)
        }
    }

    @Test func balancedNotificationDoesNotReappearAtOfficeHoursBoundary() throws {
        final class WallClock { var now = ISO8601DateFormatter().date(from: "2026-09-27T00:00:30Z")! }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settings = SettingsStore(url: directory.appendingPathComponent("settings.json"))
        settings.update {
            $0.officeHours = OfficeHours(enabled: true, weekdays: [1], startMinute: 0, endMinute: 1)
            $0.reminderStyle = .notification
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let clock = WallClock()
        let model = AppContainer(settings: settings,
            statistics: StatisticsStore(url: directory.appendingPathComponent("stats.json")),
            wallClock: { clock.now }, localCalendar: { calendar })
        defer { model.stop() }
        var shown = 0
        model.showReminder = { shown += 1 }
        model.reminderKinds = [.short]
        model.markReminderShown(at: 0)
        clock.now = ISO8601DateFormatter().date(from: "2026-09-27T00:01:00Z")!
        model.tick(now: 5, idle: 0, deliberateIdle: .infinity)
        #expect(shown == 0)
        #expect(model.outsideOfficeHours)
        #expect(model.reminderKinds.isEmpty)
    }
}
