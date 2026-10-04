import AppKit
import Foundation
import Testing
@testable import Offscreen

@Suite @MainActor struct QuietSignalTests {
    @Test func audioInputRequiresPositiveEvidenceAndPreservesUnavailable() {
        #expect(AudioInputPolicy.aggregate([]) == false)
        #expect(AudioInputPolicy.aggregate([false, false]) == false)
        #expect(AudioInputPolicy.aggregate([false, nil]) == nil)
        #expect(AudioInputPolicy.aggregate([nil, true]) == true)
        #expect(AudioInputPolicy.aggregate([true, false]) == true)
    }

    @Test func nativeFullscreenNeverInfersFromHiddenMenuOrDock() {
        #expect(QuietSignalMonitor.nativeFullScreen(nil) == nil)
        #expect(QuietSignalMonitor.nativeFullScreen([]) == false)
        #expect(QuietSignalMonitor.nativeFullScreen([.autoHideDock, .autoHideMenuBar]) == false)
        #expect(QuietSignalMonitor.nativeFullScreen([.hideDock, .hideMenuBar]) == false)
        #expect(QuietSignalMonitor.nativeFullScreen([.fullScreen, .autoHideMenuBar]) == true)
    }

    @Test func selectedAppMatchesOnlyExactFrontmostIdentifier() {
        let ids = ["org.example.Focus"]
        #expect(SelectedAppPolicy.matches(frontmostID: "org.example.Focus", selectedIDs: ids) == true)
        for id in ["org.example.Other", "org.example.Focus.helper", "org.example.focus"] {
            #expect(SelectedAppPolicy.matches(frontmostID: id, selectedIDs: ids) == false)
        }
        #expect(SelectedAppPolicy.matches(frontmostID: nil, selectedIDs: ids) == nil)
        #expect(SelectedAppPolicy.matches(frontmostID: "", selectedIDs: ids) == nil)
        #expect(SelectedAppPolicy.matches(frontmostID: "org.example.Focus", selectedIDs: []) == false)
    }

    @Test func allNewSignalsAreQuietOnlyAndRequireOptIn() {
        for enabled in [false, true] {
            for audio in [nil, false, true] as [Bool?] {
                for fullscreen in [nil, false, true] as [Bool?] {
                    for selected in [nil, false, true] as [Bool?] {
                        var config = AppSettings()
                        config.audioInputSuppression = enabled
                        config.fullScreenSuppression = enabled
                        config.selectedAppSuppression = enabled
                        config.selectedAppBundleIDs = ["org.example.Focus"]
                        let decision = SmartPause(config: config, videoPlaying: false, watching: false,
                            cameraActive: nil, focusActive: nil, presenting: false,
                            audioInputActive: audio, fullScreenActive: fullscreen, selectedAppActive: selected)
                        #expect(!decision.keepsCounting)
                        #expect(decision.quietReasons.contains(.audioInput) == (enabled && audio == true))
                        #expect(decision.quietReasons.contains(.fullScreen) == (enabled && fullscreen == true))
                        #expect(decision.quietReasons.contains(.selectedApp) == (enabled && selected == true))
                    }
                }
            }
        }
    }

    @Test func oldSignalsKeepTheirCountingAndOrderedReasons() {
        var config = AppSettings()
        config.cameraSuppression = true; config.focusSuppression = true
        config.audioInputSuppression = true; config.fullScreenSuppression = true; config.selectedAppSuppression = true
        config.selectedAppBundleIDs = ["org.example.Focus"]
        let result = SmartPause(config: config, videoPlaying: false, watching: false,
            cameraActive: true, focusActive: true, presenting: true,
            audioInputActive: true, fullScreenActive: true, selectedAppActive: true)
        #expect(result.keepsCounting)
        #expect(result.quietReasons == [.presentation, .camera, .focus, .audioInput, .fullScreen, .selectedApp])
    }

    @Test func defaultsAndLegacyMigrationDoNotEnableNewSignals() throws {
        for data in [Data("{}".utf8), try JSONEncoder().encode(AppSettings())] {
            var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
            for key in ["audioInputSuppression", "fullScreenSuppression", "selectedAppSuppression", "selectedAppBundleIDs"] { object.removeValue(forKey: key) }
            let result = try SettingsCodec.decode(JSONSerialization.data(withJSONObject: object), strict: true)
            #expect(!result.audioInputSuppression && !result.fullScreenSuppression && !result.selectedAppSuppression)
            #expect(result.selectedAppBundleIDs.isEmpty)
        }
    }

    @Test func settingsRoundTripPersistsOnlyExplicitAppPreferences() throws {
        var config = AppSettings()
        config.audioInputSuppression = true; config.fullScreenSuppression = true; config.selectedAppSuppression = true
        config.selectedAppBundleIDs = ["org.example.Focus", "org.example.Editor"]
        let data = try SettingsCodec.export(config)
        let copy = try SettingsCodec.decode(data, strict: true)
        #expect(copy.audioInputSuppression && copy.fullScreenSuppression && copy.selectedAppSuppression)
        #expect(copy.selectedAppBundleIDs == config.selectedAppBundleIDs)
        let text = String(decoding: data, as: UTF8.self)
        for key in ["audioInputActive", "fullScreenActive", "selectedAppActive", "frontmostID", "usageHistory"] { #expect(!text.contains(key)) }
    }

    @Test func selectionValidationBoundsAndRejectsHostileImports() throws {
        let invalid = ["", "org.example.App/path", "org.example.App\n", "file:///application", "org.example. App", String(repeating: "x", count: 256)]
        #expect(SelectedAppPolicy.isValidID("org.example.App-2"))
        let tooMany = (0...32).map { "org.example.App\($0)" }
        for ids in invalid.map({ [$0] }) + [tooMany, ["org.example.App", "org.example.App"]] {
            var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(AppSettings())) as? [String: Any])
            object["selectedAppBundleIDs"] = ids
            #expect(throws: (any Error).self) { try SettingsCodec.decode(JSONSerialization.data(withJSONObject: object), strict: true) }
        }
        let normalized = SelectedAppPolicy.normalized(["org.example.App", "org.example.App"] + invalid + tooMany)
        #expect(normalized.count == 32 && normalized.first == "org.example.App")
        #expect(SelectedAppPolicy.isValidSelection(normalized))
    }

    @Test func wrongTypesAndTransientFieldsAreRejected() throws {
        for (key, value) in [("audioInputSuppression", "true"), ("fullScreenSuppression", "true"), ("selectedAppSuppression", "true"), ("selectedAppBundleIDs", "org.example.App"), ("audioInputActive", "true")] {
            var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(AppSettings())) as? [String: Any])
            object[key] = value
            #expect(throws: (any Error).self) { try SettingsCodec.decode(JSONSerialization.data(withJSONObject: object), strict: true) }
        }
    }

    private func withModel(_ body: (AppContainer, () -> Void) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SettingsStore(url: directory.appendingPathComponent("settings.json"))
        store.update {
            $0.videoEnabled = false; $0.audioInputSuppression = true
            $0.fullScreenSuppression = true; $0.selectedAppSuppression = true
            $0.selectedAppBundleIDs = ["org.example.Focus"]
        }
        var snapshot = QuietSignalSnapshot(audioInputActive: true, fullScreenActive: true, selectedAppActive: true)
        let model = AppContainer(settings: store, statistics: StatisticsStore(url: directory.appendingPathComponent("stats.json")),
                                 quietSignalReader: { _ in snapshot })
        defer { model.stop() }
        model.refreshQuietSignals()
        try body(model, { snapshot = QuietSignalSnapshot(); model.refreshQuietSignals() })
    }

    @Test func coordinatorHoldsAllStylesAndModesThenOneReminderAfterGrace() throws {
        for style in ReminderStyle.allCases {
            for mode in DifficultyMode.allCases {
                try withModel { model, clearSignals in
                    model.settings.update { $0.reminderStyle = style; $0.skipMode = mode }
                    var shown = 0; model.showReminder = { shown += 1 }
                    model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
                    model.breakEngine.advance(by: 1200)
                    model.tick(now: 1, idle: 0, deliberateIdle: .infinity)
                    #expect(model.suppressing && !model.canPresent && shown == 0)
                    #expect(model.breakEngine.shortBreaksSinceLong == 0 && model.breakEngine.explicitDeferrals == 0)
                    clearSignals()
                    model.tick(now: 2, idle: 0, deliberateIdle: .infinity)
                    model.tick(now: 61, idle: 0, deliberateIdle: .infinity)
                    #expect(shown == 0 && model.statusText == L("Alerts resume shortly"))
                    model.tick(now: 62, idle: 0, deliberateIdle: .infinity)
                    model.tick(now: 63, idle: 0, deliberateIdle: .infinity)
                    #expect(shown == 1 && model.reminderKinds == [.short])
                    #expect(model.breakEngine.shortBreaksSinceLong == 0 && model.breakEngine.explicitDeferrals == 0)
                }
            }
        }
    }

    @Test func inactivityStillPausesAndCreditsOnlyTheNormalNaturalRest() throws {
        try withModel { model, _ in
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            model.breakEngine.advance(by: 500)
            model.tick(now: 1, idle: 0, deliberateIdle: .infinity)
            #expect(model.activity == .active && model.breakEngine.workAccrued == 501)
            model.tick(now: 2, idle: 130, deliberateIdle: .infinity)
            #expect(model.activity == .away && model.breakEngine.shortBreaksSinceLong == 1)
            #expect(model.breakEngine.workAccrued == 0)
            model.tick(now: 3, idle: 131, deliberateIdle: .infinity)
            #expect(model.breakEngine.shortBreaksSinceLong == 1)
        }
    }

    @Test func independentPauseSleepAndOfficeHoursKeepTheirRules() throws {
        try withModel { model, _ in
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            model.pauseTracking(.untilResumed)
            model.tick(now: 1, idle: 0, deliberateIdle: .infinity)
            #expect(model.isPaused && !model.canPresent && model.breakEngine.workAccrued == 0)
            model.resumeManualPause()
            model.settings.update { $0.officeHours.enabled = true; $0.officeHours.weekdays = [] }
            model.tick(now: 2, idle: 0, deliberateIdle: .infinity)
            #expect(model.outsideOfficeHours && model.breakEngine.workAccrued == 0)
            model.settings.update { $0.officeHours.enabled = false }
            model.suspendTracking()
            #expect(model.audioInputActive == nil && model.fullScreenActive == nil && model.selectedAppActive == nil)
            model.tick(now: 4, idle: 0, deliberateIdle: .infinity)
            #expect(model.activity == .sleeping && !model.canPresent)
        }
    }


    @Test func manualRestStaysAvailableWhileQuietAndCompletesNormally() throws {
        try withModel { model, _ in
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            model.beginRest(.short, now: 0)
            model.tick(now: 1, idle: 100, deliberateIdle: .infinity)
            #expect(model.suppressing && model.activeRest == .short)
            model.breakEngine.advance(by: 20)
            #expect(model.activeRest == nil && model.breakEngine.shortBreaksSinceLong == 1)
        }
    }

    @Test func finalPointerCountdownAndPreviewRespectQuietSignals() throws {
        try withModel { model, clearSignals in
            model.settings.update { $0.showCursorCountdown = true }
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            model.breakEngine.advance(by: 1190)
            #expect(model.cursorCountdownSeconds == nil && !model.canPreview)
            var shown = 0; model.showReminder = { shown += 1 }
            model.previewReminder()
            #expect(!model.isPreview && shown == 0 && model.breakEngine.workAccrued == 1190)
            clearSignals()
            #expect(model.cursorCountdownSeconds == 10)
            model.previewReminder()
            #expect(model.isPreview && model.cursorCountdownSeconds == nil && shown == 1)
            #expect(model.breakEngine.workAccrued == 1190 && model.breakEngine.shortBreaksSinceLong == 0)
        }
    }

    @Test func overlappingQuietReasonsAndTypingCannotRestartABudget() throws {
        try withModel { model, clearSignals in
            model.settings.update { $0.typingDeferralEnabled = true }
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            model.breakEngine.advance(by: 1200)
            var shown = 0; model.showReminder = { shown += 1 }
            model.tick(now: 1, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            model.settings.update { $0.audioInputSuppression = false; $0.fullScreenSuppression = false }
            #expect(model.suppressionReasons == [L("Selected app in front")])
            model.tick(now: 10, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            #expect(shown == 0 && !model.typingDeferred)
            clearSignals()
            model.tick(now: 11, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            model.tick(now: 71, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            model.tick(now: 72, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            #expect(model.typingDeferred && shown == 0)
            model.settings.update { $0.audioInputSuppression = true }
            // The injected reader still reports unavailable; opting in cannot invent a quiet signal.
            model.tick(now: 102, idle: 0, deliberateIdle: .infinity, keyboardIdle: 0)
            #expect(!model.typingDeferred && shown == 1)
        }
    }

    @Test func removingLastAppCannotRetainAQuietReason() throws {
        try withModel { model, _ in
            model.settings.update { $0.audioInputSuppression = false; $0.fullScreenSuppression = false; $0.selectedAppBundleIDs = [] }
            #expect(!model.suppressing)
        }
    }

    @Test func optOutImmediatelyRemovesCachedQuietReasons() throws {
        try withModel { model, _ in
            #expect(model.suppressionReasons.count == 3)
            model.settings.update { $0.audioInputSuppression = false; $0.fullScreenSuppression = false; $0.selectedAppSuppression = false }
            #expect(!model.suppressing)
        }
    }

    @Test func selectedAppsPersistAcrossRelaunchWithoutSnapshots() throws {
        try withModel { model, _ in
            model.settings.flush()
            let reloaded = SettingsStore(url: model.settings.pauseFileURL.deletingLastPathComponent().appendingPathComponent("settings.json"))
            #expect(reloaded.settings.selectedAppBundleIDs == ["org.example.Focus"])
            let reopened = AppContainer(settings: reloaded, statistics: model.statistics, quietSignalReader: { _ in QuietSignalSnapshot() })
            defer { reopened.stop() }
            #expect(!reopened.suppressing && reopened.audioInputActive == nil)
        }
    }
}
