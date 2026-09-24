import Testing
import Foundation
@testable import Offscreen

@Suite struct InteractionTests {
    @Test func pauseNeverAddsAnotherSymbolBesideMenuIcon() {
        #expect(MenuTitle.make(show: true, paused: true, countdown: "17:00") == "")
        #expect(MenuTitle.make(show: true, paused: false, countdown: "17:00") == " 17:00")
        #expect(MenuTitle.make(show: false, paused: false, countdown: "17:00") == "")
    }
    @Test func durationDraftOnlyAcceptsBoundedIntegers() {
        #expect(DurationInput.parse(" 30 ", within: 5...120) == 30)
        for text in ["", "3", "121", "3.5", "-20", "+20", "1e2", "999999999999999999", "٣٠"] {
            #expect(DurationInput.parse(text, within: 5...120) == nil)
        }
    }
    @Test func settingsMigrateWithSurfaceDefaults() throws {
        let old = try SettingsCodec.decode(Data(#"{"schemaVersion":2,"eyeMinutes":35,"displayTarget":"all"}"#.utf8))
        #expect(old.eyeMinutes == 35 && old.displayTarget == .all)
        #expect(old.alertSurface == .system && old.surfaceDensity == 0.65)
    }
    @Test func invalidOpacityNeverMakesAlertsInvisible() throws {
        var settings = try SettingsCodec.decode(Data(#"{"surfaceDensity":-100,"fullScreenDim":100}"#.utf8))
        #expect(settings.surfaceDensity == 0.3 && settings.fullScreenDim == 1)
        settings.surfaceDensity = .nan; settings.fullScreenDim = .infinity; settings.validate()
        #expect(settings.surfaceDensity == 0.65 && settings.fullScreenDim == 0.85)
    }
    @Test func appearanceRoundTripRetainsUserChoices() throws {
        var original = AppSettings(); original.alertSurface = .solid; original.surfaceDensity = 0.8; original.fullScreenDim = 0.7
        #expect(try SettingsCodec.decode(SettingsCodec.export(original), strict: true) == original)
    }
    @Test func openingFromSecondDisplayStaysThere() {
        let second = CGRect(x: -1920, y: 240, width: 1920, height: 1080)
        let original = CGRect(x: 200, y: 100, width: 780, height: 688)
        let result = DisplayLayout.windowFrame(current: original, visible: second, centered: true)
        #expect(second.contains(result))
        #expect(result.midX == second.midX && result.midY == second.midY)
    }
    @Test func disconnectedDisplayWindowIsRecovered() {
        let visible = CGRect(x: 0, y: 35, width: 1280, height: 680)
        let old = CGRect(x: -1600, y: 600, width: 780, height: 900)
        #expect(visible.contains(DisplayLayout.windowFrame(current: old, visible: visible, centered: false)))
    }
    @Test func dashboardAvoidsBothDisplayEdges() {
        let screen = CGRect(x: 1920, y: 20, width: 1280, height: 700)
        for x in [1921.0, 3199.0] {
            let frame = DisplayLayout.dashboardFrame(visible: screen, anchor: CGPoint(x: x, y: 740), size: CGSize(width: 342, height: 620))
            #expect(screen.contains(frame))
        }
    }
    @Test func isolatedMouseJiggleDoesNotEndRest() {
        var policy = RestReturnPolicy()
        #expect({ !policy.shouldResume(now: 10, restStarted: 0, idle: 0, deliberateIdle: 20) }())
        #expect({ !policy.shouldResume(now: 11, restStarted: 0, idle: 1, deliberateIdle: 21) }())
        #expect({ !policy.shouldResume(now: 12, restStarted: 0, idle: 2, deliberateIdle: 22) }())
        #expect({ !policy.shouldResume(now: 13, restStarted: 0, idle: 3, deliberateIdle: 23) }())
    }
    @Test func continuousMovementOrDeliberateInputResumes() {
        var policy = RestReturnPolicy()
        for n in 10...12 { #expect({ !policy.shouldResume(now: Double(n), restStarted: 0, idle: 0, deliberateIdle: 100) }()) }
        #expect({ policy.shouldResume(now: 13, restStarted: 0, idle: 0, deliberateIdle: 100) }())
        policy.reset()
        #expect({ policy.shouldResume(now: 10, restStarted: 0, idle: 0, deliberateIdle: 0) }())
    }
    @Test func openingClickCannotCancelNewRest() {
        var policy = RestReturnPolicy()
        #expect({ !policy.shouldResume(now: 2, restStarted: 0, idle: 0, deliberateIdle: 0) }())
        #expect({ !policy.shouldResume(now: 4, restStarted: 0, idle: 4, deliberateIdle: 4) }())
    }
}
