import Foundation
import Testing
@testable import Offscreen

/// Composition checks for the M1–M9 development app, not physical OS verification.
@Suite struct ReleaseReadinessTests {
    private final class Fixture {
        let directory: URL
        let start = ISO8601DateFormatter().date(from: "2026-10-05T09:00:00Z")!
        var now: Date
        var uptime = 0.0
        var signals = QuietSignalSnapshot()
        var calendar: Calendar
        var settingsURL: URL { directory.appendingPathComponent("settings.json") }
        var statsURL: URL { directory.appendingPathComponent("statistics.json") }

        init() throws {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            now = start
            calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        }
        func model() -> AppContainer {
            AppContainer(settings: SettingsStore(url: settingsURL), statistics: StatisticsStore(url: statsURL, now: now),
                wallClock: { self.now }, localCalendar: { self.calendar }, quietSignalReader: { _ in self.signals })
        }
        func configure(_ model: AppContainer) {
            model.settings.update {
                $0.workMinutes = 5; $0.shortRestSeconds = 20; $0.longRestMinutes = 1
                $0.shortBreaksBeforeLong = 1; $0.videoEnabled = false
                $0.showCursorCountdown = true; $0.typingDeferralEnabled = true
                $0.audioInputSuppression = true; $0.fullScreenSuppression = true
                $0.selectedAppSuppression = true; $0.selectedAppBundleIDs = ["org.example.Focus"]
                $0.skipMode = .balanced
            }
        }
        func sample(_ model: AppContainer, idle: Double = 0, keyboard: Double? = nil) {
            model.tick(now: uptime, idle: idle, deliberateIdle: .infinity, keyboardIdle: keyboard)
        }
        func advance(_ model: AppContainer, seconds: Int, resting: Bool = false, keyboard: Double? = nil) {
            for second in 1...seconds {
                uptime += 1; now = now.addingTimeInterval(1)
                sample(model, idle: resting ? Double(second) : 0, keyboard: keyboard)
            }
        }
        func score(_ model: AppContainer) -> ScreenScoreTotals? { ScreenScoreTotals.combining(model.statistics.days) }
        func remove() { try? FileManager.default.removeItem(at: directory) }
    }

    @Test func quietReturnTypingSkipGateAndCadenceResolveOneOpportunity() throws {
        let f = try Fixture(); defer { f.remove() }
        let m = f.model(); defer { m.stop() }
        f.configure(m); m.setStatisticsEnabled(true)
        var shown = 0; m.showReminder = { shown += 1 }
        f.sample(m); f.advance(m, seconds: 290)
        #expect(m.cursorCountdownSeconds == 10)
        f.signals = QuietSignalSnapshot(audioInputActive: true, fullScreenActive: true, selectedAppActive: true)
        m.refreshQuietSignals(); f.advance(m, seconds: 10, keyboard: 0)
        #expect(m.cursorCountdownSeconds == nil && shown == 0 && m.suppressing)
        #expect(f.score(m) == nil && m.breakEngine.shortBreaksSinceLong == 0)
        f.signals = QuietSignalSnapshot(); m.refreshQuietSignals()
        f.advance(m, seconds: 60, keyboard: 0)
        #expect(shown == 0 && !m.typingDeferred)
        f.advance(m, seconds: 1, keyboard: 0)
        #expect(m.typingDeferred && shown == 0)
        f.advance(m, seconds: 30, keyboard: 0)
        #expect(!m.typingDeferred && shown == 1 && m.skipCountdown == 5)
        f.advance(m, seconds: 4, keyboard: 0)
        #expect(!m.skipBreak(now: f.uptime))
        f.advance(m, seconds: 1, keyboard: 0)
        #expect(m.skipBreak(now: f.uptime))
        #expect(f.score(m) == ScreenScoreTotals(completed: 0, opportunities: 1))
        #expect(m.nextKind == .short && m.breakEngine.shortBreaksSinceLong == 0)
        for kind in [MolaKind.short, .long] {
            f.advance(m, seconds: 300, keyboard: 2)
            #expect(m.nextKind == kind)
            m.beginRest(kind, now: f.uptime)
            #expect(m.cursorCountdownSeconds == nil)
            f.advance(m, seconds: kind == .short ? 20 : 60, resting: true)
            #expect(m.activeRest == nil)
        }
        #expect(f.score(m) == ScreenScoreTotals(completed: 2, opportunities: 3))
        #expect(f.score(m)?.percent == 67)
        #expect(m.nextKind == .short && m.breakEngine.shortBreaksSinceLong == 0)
    }

    @Test func officeClosureManualPauseAndOvernightSuspensionPreservePendingCycle() throws {
        let f = try Fixture(); defer { f.remove() }
        f.now = ISO8601DateFormatter().date(from: "2026-10-05T09:54:58Z")!
        let m = f.model(); defer { m.stop() }
        f.configure(m)
        m.settings.update { $0.officeHours = OfficeHours(enabled: true, weekdays: [2, 3], startMinute: 540, endMinute: 600) }
        m.setStatisticsEnabled(true)
        f.signals = QuietSignalSnapshot(selectedAppActive: true); m.refreshQuietSignals()
        var shown = 0; m.showReminder = { shown += 1 }
        f.sample(m); f.advance(m, seconds: 300)
        #expect(m.breakEngine.workAccrued == 300 && shown == 0)
        f.advance(m, seconds: 2)
        #expect(m.outsideOfficeHours && m.cursorCountdownSeconds == nil)
        let work = m.breakEngine.workAccrued
        m.pauseTracking(.untilResumed); m.suspendTracking()
        #expect(m.pause.reasons.contains(.manual) && m.pause.reasons.contains(.officeHours))
        f.now = ISO8601DateFormatter().date(from: "2026-10-06T09:00:00Z")!
        f.uptime += 23 * 3600
        m.resumeTracking(after: 23 * 3600)
        f.signals = QuietSignalSnapshot(); m.refreshQuietSignals()
        #expect(m.isPaused && !m.outsideOfficeHours)
        #expect(m.breakEngine.workAccrued == work && m.breakEngine.shortBreaksSinceLong == 0)
        #expect(f.score(m) == nil && shown == 0)
        m.resumeManualPause(); f.sample(m)
        f.advance(m, seconds: 61, keyboard: 2)
        #expect(shown == 1 && f.score(m) == nil)
        m.beginRest(.short, now: f.uptime); f.advance(m, seconds: 20, resting: true)
        #expect(f.score(m) == ScreenScoreTotals(completed: 1, opportunities: 1))
        #expect(m.breakEngine.shortBreaksSinceLong == 1 && m.nextKind == .long)
    }

    @Test func legacyMigrationOptInRestAndReopenKeepHistoricalMeaning() throws {
        let f = try Fixture(); defer { f.remove() }
        try Data(#"{"schemaVersion":2,"eyeMinutes":5,"movementMinutes":10,"eyeRestSeconds":20,"movementRestMinutes":1,"language":"tr","videoEnabled":false,"didFinishWelcome":true}"#.utf8).write(to: f.settingsURL)
        try Data(#"{"version":1,"enabled":false,"weekly":false,"retention":90,"days":[{"day":"2026-10-04","active":600,"video":0,"watching":0,"observed":600,"breaks":2,"eyes":2,"movement":1,"natural":0,"rest":140}]}"#.utf8).write(to: f.statsURL)
        let m = f.model(); defer { m.stop() }
        #expect(m.config.workMinutes == 5 && m.config.shortBreaksBeforeLong == 1)
        #expect(m.config.migrationNoticePending && m.config.language == .tr)
        #expect(!m.config.typingDeferralEnabled && !m.config.audioInputSuppression && !m.config.showCursorCountdown)
        #expect(!m.statistics.enabled && f.score(m) == nil)
        m.setStatisticsEnabled(true); f.sample(m); f.advance(m, seconds: 300)
        m.beginRest(.short, now: f.uptime); f.advance(m, seconds: 20, resting: true)
        #expect(f.score(m) == ScreenScoreTotals(completed: 1, opportunities: 1))
        m.settings.update { $0.officeHours = OfficeHours(enabled: true, weekdays: [], startMinute: 540, endMinute: 600) }
        m.pauseTracking(.untilResumed); m.stop()
        let reopened = f.model(); defer { reopened.stop() }
        #expect(reopened.isPaused && reopened.outsideOfficeHours)
        #expect(reopened.breakEngine.workAccrued == 0 && reopened.nextKind == .long)
        #expect(reopened.config.cycleShortCount == 1 && reopened.config.language == .tr)
        #expect(reopened.statistics.days.first?.eyes == 2 && reopened.statistics.days.first?.movement == 1)
        #expect(reopened.statistics.days.first?.score == nil)
        #expect(f.score(reopened) == ScreenScoreTotals(completed: 1, opportunities: 1))
        let backup = try SettingsCodec.decode(SettingsCodec.export(reopened.config), strict: true)
        #expect(backup.cycleShortCount == 0 && !backup.migrationNoticePending)
        #expect(!String(decoding: try SettingsCodec.export(reopened.config), as: UTF8.self).contains("opportunities"))
    }
}
