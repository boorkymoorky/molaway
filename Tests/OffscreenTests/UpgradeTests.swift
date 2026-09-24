import Testing
import Foundation
@testable import Offscreen

@Suite struct UpgradeTests {
    @Test func migratesOriginalSettingsWithoutLosingPreferences() throws {
        let data = Data(#"{"eyeMinutes":35,"movementMinutes":75,"chromeVideoEnabled":false,"reminderSound":true,"didFinishWelcome":true}"#.utf8)
        let settings = try SettingsCodec.decode(data, strict: true)
        #expect(settings.eyeMinutes == 35)
        #expect(settings.movementMinutes == 75)
        #expect(!settings.videoEnabled)
        #expect(settings.reminderTone == .tink)
        #expect(settings.reminderStyle == .corner)
        #expect(settings.didFinishWelcome)
        #expect(settings.schemaVersion == 2)
    }
    @Test func newSettingsUseSafeDefaults() {
        let settings = AppSettings()
        #expect(settings.reminderStyle == .banner)
        #expect(!settings.cameraSuppression && !settings.focusSuppression)
        #expect(settings.pauseTone == .none && settings.resumeTone == .none)
        #expect(settings.displayTarget == .cursor)
        #expect(settings.language == .system)
    }
    @Test func newerSchemaRejected() { #expect(throws: (any Error).self) { try SettingsCodec.decode(Data(#"{"schemaVersion":999}"#.utf8)) } }
    @Test func invalidEnumsRejected() { #expect(throws: (any Error).self) { try SettingsCodec.decode(Data(#"{"schemaVersion":2,"reminderStyle":"shell"}"#.utf8)) } }
    @Test func unknownImportedFieldsRejected() { #expect(throws: (any Error).self) { try SettingsCodec.decode(Data(#"{"command":"open something"}"#.utf8), strict: true) } }
    @Test func nonObjectRejected() { #expect(throws: (any Error).self) { try SettingsCodec.decode(Data("[]".utf8)) } }
    @Test func wrongTypesRejected() { #expect(throws: (any Error).self) { try SettingsCodec.decode(Data(#"{"watchingMinutes":"60"}"#.utf8)) } }
    @Test func malformedJSONRejected() { #expect(throws: (any Error).self) { try SettingsCodec.decode(Data("{".utf8)) } }
    @Test func largeImportRejectedBeforeParsing() { #expect(throws: (any Error).self) { try SettingsCodec.decode(Data(repeating: 32, count: 65_537)) } }
    @Test func extremeIntegersCannotOverflowTimers() throws {
        let data = Data("{\"eyeMinutes\":\(Int.max),\"movementMinutes\":\(Int.max),\"watchingMinutes\":\(Int.max),\"soundVolume\":5}".utf8)
        let settings = try SettingsCodec.decode(data)
        #expect(settings.eyes.workSeconds == 7200)
        #expect(settings.movement.workSeconds == 10800)
        #expect(settings.watchingMinutes == 240)
        #expect(settings.soundVolume == 1)
        var raw = AppSettings(); raw.eyeMinutes = Int.max; raw.movementRestMinutes = Int.max
        #expect(raw.eyes.workSeconds == 7200)
        #expect(raw.movement.shortBreakSeconds == 900)
    }
    @Test func exportedSettingsNeverEnablePermissionFeatures() throws {
        var settings = AppSettings(); settings.cameraSuppression = true; settings.focusSuppression = true; settings.didFinishWelcome = true
        settings.watchingMinutes = 45
        let data = try SettingsCodec.export(settings)
        let copy = try SettingsCodec.decode(data, strict: true)
        #expect(!copy.cameraSuppression && !copy.focusSuppression)
        #expect(!copy.didFinishWelcome)
        #expect(copy.watchingMinutes == 45)
    }
    @Test func versionTwoRoundTripPreservesAllAppearanceOptions() throws {
        var settings = AppSettings(); settings.reminderStyle = .fullScreen; settings.displayTarget = .all; settings.language = .tr; settings.accent = .rose; settings.appearance = .dark; settings.reminderTone = .bell
        #expect(try SettingsCodec.decode(JSONEncoder().encode(settings)) == settings)
    }
    @Test func quietPeriodCoalescesAndDelaysReminders() {
        var policy = ReminderPolicy()
        #expect(policy.update(now: 0, suppressed: true, eligible: true, due: [.eyes]).isEmpty)
        #expect(policy.update(now: 100, suppressed: true, eligible: true, due: [.movement]).isEmpty)
        #expect(policy.update(now: 101, suppressed: false, eligible: true, due: []).isEmpty)
        #expect(policy.update(now: 160, suppressed: false, eligible: true, due: []).isEmpty)
        #expect(policy.update(now: 161, suppressed: false, eligible: true, due: []) == [.eyes, .movement])
        #expect(policy.update(now: 162, suppressed: false, eligible: true, due: []).isEmpty)
    }
    @Test func quietResumingRestartsGracePeriod() {
        var policy = ReminderPolicy()
        _ = policy.update(now: 0, suppressed: true, eligible: true, due: [.eyes])
        _ = policy.update(now: 10, suppressed: false, eligible: true, due: [])
        _ = policy.update(now: 20, suppressed: true, eligible: true, due: [])
        _ = policy.update(now: 30, suppressed: false, eligible: true, due: [])
        #expect(policy.update(now: 70, suppressed: false, eligible: true, due: []).isEmpty)
        #expect(policy.update(now: 90, suppressed: false, eligible: true, due: []) == [.eyes])
    }
    @Test func completedRestRemovesPendingReminder() {
        var policy = ReminderPolicy()
        _ = policy.update(now: 0, suppressed: true, eligible: true, due: [.eyes, .movement])
        policy.clear(.eyes)
        _ = policy.update(now: 1, suppressed: false, eligible: true, due: [])
        #expect(policy.update(now: 61, suppressed: false, eligible: true, due: []) == [.movement])
    }
    @Test func lockedOrPausedNeverDeliversPendingReminder() {
        var policy = ReminderPolicy()
        #expect(policy.update(now: 0, suppressed: false, eligible: false, due: [.eyes]).isEmpty)
        #expect(policy.update(now: 60, suppressed: false, eligible: false, due: []).isEmpty)
        #expect(policy.update(now: 61, suppressed: false, eligible: true, due: []) == [.eyes])
    }
    @Test func genericMediaDoesNotPretendToBeVideo() {
        for name in ["Playing audio", "Audio Wake Lock", "Screen Wake Lock", "disable screen saver", "media playback", ""] {
            #expect(!MediaRule.matches(name: name, type: "NoDisplaySleepAssertion", level: 1))
        }
        #expect(MediaRule.matches(name: "Video Wake Lock", type: "NoDisplaySleepAssertion", level: 1))
        #expect(!MediaRule.matches(name: "Video Wake Lock", type: "PreventUserIdleSystemSleep", level: 1))
        #expect(!MediaRule.matches(name: "Video Wake Lock", type: "NoDisplaySleepAssertion", level: 0))
    }
    @Test func disabledActivityCannotAccrueDespiteVideo() {
        var policy = ActivityAccounting()
        _ = policy.step(now: 0, idle: 0, video: true, locked: false)
        #expect(policy.step(now: 1, idle: 1, video: true, locked: false, paused: true).activeSeconds == 0)
        #expect(policy.step(now: 2, idle: 2, video: true, locked: true).activeSeconds == 0)
    }
}

@Suite struct SafeFileAndLayoutTests {
    @Test func fileReaderRejectsSymlinksAndLargeFiles() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("settings.json")
        try Data(#"{"schemaVersion":2,"eyeMinutes":45}"#.utf8).write(to: file)
        #expect(try SettingsCodec.read(file).eyeMinutes == 45)
        let link = directory.appendingPathComponent("link.json")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: file)
        #expect(throws: (any Error).self) { try SettingsCodec.read(link) }
        try Data(repeating: 0, count: 65_537).write(to: file)
        #expect(throws: (any Error).self) { try SettingsCodec.read(file) }
        #expect(throws: (any Error).self) { try SettingsCodec.read(directory) }
    }
    @Test func monitorsWithNegativeOriginsAndCursorGapAreHandled() {
        let screens = [CGRect(x: 0, y: 0, width: 1920, height: 1080), CGRect(x: -1280, y: 200, width: 1280, height: 1024)]
        #expect(DisplayLayout.selectedIndices(frames: screens, cursor: CGPoint(x: -100, y: 400), target: .cursor) == [1])
        #expect(DisplayLayout.selectedIndices(frames: screens, cursor: .zero, target: .all) == [0, 1])
        #expect(DisplayLayout.selectedIndices(frames: screens, cursor: CGPoint(x: 8000, y: 0), target: .cursor) == [0])
        #expect(DisplayLayout.selectedIndices(frames: [], cursor: .zero, target: .all).isEmpty)
        #expect(DisplayLayout.selectedIndices(frames: screens, cursor: CGPoint(x: -100, y: 400), target: .primary) == [0])
    }
    @Test func panelsStayInsideSmallDisplays() {
        let visible = CGRect(x: -300, y: 42, width: 320, height: 400)
        for centered in [false, true] {
            let frame = DisplayLayout.panelFrame(visible: visible, desired: CGSize(width: 520, height: 240), centered: centered)
            #expect(visible.contains(frame))
            if centered { #expect(frame.midX == visible.midX) }
        }
    }
    @Test func formattingUnexpectedNumbersCannotCrash() {
        #expect(Format.clock(.nan) == "0:00")
        #expect(Format.clock(.infinity) == "0:00")
        #expect(Format.clock(-1) == "0:00")
        #expect(Format.clock(65) == "1:05")
    }
}
