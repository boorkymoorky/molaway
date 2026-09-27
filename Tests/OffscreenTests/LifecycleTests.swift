import Testing
import Foundation
@testable import Offscreen

@Suite struct LifecycleTests {
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
    private func configured(_ model: AppContainer) {
        model.settings.update {
            $0.workMinutes = 20
            $0.shortRestSeconds = 20
            $0.longRestMinutes = 2
            $0.shortBreaksBeforeLong = 3
        }
    }
    private func complete(_ model: AppContainer, kind: MolaKind) {
        model.beginRest(kind, now: 0)
        model.breakEngine.advance(by: kind == .short ? 20 : 120)
    }
    @Test func threeShortsThenLongAndManualLongResets() throws {
        try withModel { model, _ in
            configured(model)
            for count in 1...3 {
                #expect(model.nextKind == .short)
                complete(model, kind: .short)
                #expect(model.breakEngine.shortBreaksSinceLong == count)
            }
            #expect(model.nextKind == .long)
            complete(model, kind: .long)
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
            complete(model, kind: .short)
            complete(model, kind: .long) // manual long before it is due
            #expect(model.nextKind == .short)
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
        }
    }
    @Test func earlyReturnAndSnoozeDoNotAdvanceCadence() throws {
        try withModel { model, _ in
            configured(model)
            model.breakEngine.advance(by: 1200)
            model.reminderKinds = [.short]
            model.snoozeReminder()
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
            #expect(model.breakEngine.isExplicitlyDeferred)
            model.beginRest(.short, now: 0)
            model.breakEngine.advance(by: 5)
            model.cancelRest()
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
            #expect(model.breakEngine.workAccrued == 1200)
        }
    }
    @Test func skipAndNaturalAbsenceCountAtMostOnce() throws {
        try withModel { model, _ in
            configured(model)
            model.breakEngine.startBreakNow()
            model.breakEngine.skipBreak()
            #expect(model.nextKind == .short)
            model.suspendTracking()
            model.resumeTracking(after: 120)
            #expect(model.breakEngine.shortBreaksSinceLong == 1)
            model.resumeTracking(after: 120)
            #expect(model.breakEngine.shortBreaksSinceLong == 1)
        }
    }
    @Test func sleepLockDoesNotAccrueWorkOrCompleteActiveRest() throws {
        try withModel { model, _ in
            configured(model)
            model.breakEngine.advance(by: 600)
            model.beginRest(.short, now: 0)
            model.breakEngine.advance(by: 5)
            model.suspendTracking()
            #expect(model.activeRest == nil)
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
            model.resumeTracking(after: 10)
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
            #expect(model.breakEngine.workAccrued == 600)
        }
    }
    @Test func reopeningPreservesCompletedShortCountAndRestartsWork() throws {
        try withModel { model, url in
            configured(model)
            complete(model, kind: .short)
            model.settings.flush()
            let reopened = AppContainer(settings: SettingsStore(url: url),
                statistics: StatisticsStore(url: url.deletingLastPathComponent().appendingPathComponent("stats2.json")))
            #expect(reopened.breakEngine.shortBreaksSinceLong == 1)
            #expect(reopened.nextKind == .short)
            #expect(reopened.breakEngine.workAccrued == 0)
            reopened.stop()
        }
    }
}
