import AppKit
import Foundation
import Testing
@testable import Offscreen

@Suite struct CursorCountdownTests {
    private func withModel(_ body: (AppContainer, URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("settings.json")
        let model = AppContainer(settings: SettingsStore(url: url),
            statistics: StatisticsStore(url: directory.appendingPathComponent("stats.json")))
        defer { model.stop() }
        try body(model, url)
    }

    @Test func optionalFinalTenSecondsAndPersistence() throws {
        try withModel { model, url in
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            model.breakEngine.advance(by: 1191)
            #expect(model.cursorCountdownSeconds == nil)
            model.settings.update { $0.showCursorCountdown = true }
            #expect(model.cursorCountdownSeconds == 9)
            model.breakEngine.advance(by: 8)
            #expect(model.cursorCountdownSeconds == 1)
            model.breakEngine.advance(by: 1)
            #expect(model.cursorCountdownSeconds == nil)
            model.settings.flush()
            #expect(SettingsStore(url: url).settings.showCursorCountdown)
        }
        #expect(!AppSettings().showCursorCountdown)
        #expect(try !SettingsCodec.decode(Data("{}".utf8)).showCursorCountdown)
    }

    @Test func previewPauseSleepAndRestHideWithoutChangingWork() throws {
        try withModel { model, _ in
            model.settings.update { $0.showCursorCountdown = true }
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            model.breakEngine.advance(by: 1195)
            #expect(model.cursorCountdownSeconds == 5)
            let accrued = model.breakEngine.workAccrued
            model.previewReminder()
            #expect(model.cursorCountdownSeconds == nil)
            #expect(model.breakEngine.workAccrued == accrued)
            model.dismissReminder()
            #expect(model.cursorCountdownSeconds == 5)
            model.settings.update { $0.officeHours = OfficeHours(enabled: true, weekdays: []) }
            #expect(model.cursorCountdownSeconds == nil)
            model.settings.update { $0.officeHours = OfficeHours() }
            model.pauseTracking(.untilResumed)
            #expect(model.cursorCountdownSeconds == nil)
            model.resumeManualPause()
            model.suspendTracking()
            #expect(model.cursorCountdownSeconds == nil)
            model.resumeTracking(after: 0)
            model.beginRest(.short)
            #expect(model.cursorCountdownSeconds == nil)
        }
    }

    @Test func eligibilityAndDisplayGeometry() {
        #expect(CursorCountdownPolicy.seconds(remaining: 10, enabled: true, eligible: true) == 10)
        #expect(CursorCountdownPolicy.seconds(remaining: 0.1, enabled: true, eligible: true) == 1)
        for remaining in [-1.0, 0, 10.01, .infinity, .nan] {
            #expect(CursorCountdownPolicy.seconds(remaining: remaining, enabled: true, eligible: true) == nil)
        }
        #expect(CursorCountdownPolicy.seconds(remaining: 5, enabled: false, eligible: true) == nil)
        #expect(CursorCountdownPolicy.seconds(remaining: 5, enabled: true, eligible: false) == nil)
        let visible = CGRect(x: -1440, y: -900, width: 1440, height: 900)
        for cursor in [CGPoint(x: -1439, y: -899), CGPoint(x: -2, y: -2), CGPoint(x: -700, y: -450)] {
            let frame = DisplayLayout.cursorBadgeFrame(visible: visible, cursor: cursor,
                size: CGSize(width: 116, height: 46))
            #expect(visible.contains(frame))
            #expect(!frame.contains(cursor))
        }
    }

    @Test func automaticPauseAndQuietModeHideBadge() throws {
        try withModel { model, _ in
            model.settings.update { $0.showCursorCountdown = true }
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            model.breakEngine.advance(by: 1195)
            #expect(model.cursorCountdownSeconds == 5)
            model.togglePresentation()
            #expect(model.cursorCountdownSeconds == nil)
            model.togglePresentation()
            model.tick(now: 1, idle: 200, deliberateIdle: .infinity)
            #expect(model.cursorCountdownSeconds == nil)
        }
    }
}
