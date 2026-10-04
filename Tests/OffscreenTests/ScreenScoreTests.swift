import Foundation
import Testing
@testable import Offscreen

@Suite struct ScreenScoreTests {
    private let day = "2026-10-04"
    private func withModel(_ body: (AppContainer, URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settings = SettingsStore(url: directory.appendingPathComponent("settings.json"))
        settings.update { $0.skipMode = .casual; $0.videoEnabled = false }
        let model = AppContainer(settings: settings, statistics: StatisticsStore(url: directory.appendingPathComponent("statistics.json")))
        defer { model.stop() }
        model.setStatisticsEnabled(true)
        try body(model, directory)
    }
    private func due(_ model: AppContainer) {
        model.breakEngine.advance(by: Double(model.config.timing.workSeconds))
        model.reminderKinds = [model.nextKind]
        model.markReminderShown(at: 100)
    }
    private func complete(_ model: AppContainer) {
        model.beginRest(model.nextKind, now: 100)
        model.breakEngine.advance(by: model.breakEngine.breakDuration)
    }
    private func score(_ model: AppContainer) -> ScreenScoreTotals? { ScreenScoreTotals.combining(model.statistics.days) }

    @Test func ratioThresholdAndPeriodWeighting() {
        #expect(ScreenScoreTotals(completed: 2, opportunities: 2).percent == nil)
        #expect(ScreenScoreTotals(completed: 2, opportunities: 3).percent == 67)
        #expect(ScreenScoreTotals(completed: 0, opportunities: 3).percent == 0)
        #expect(ScreenScoreTotals(completed: 3, opportunities: 3).percent == 100)
        let rows = [DailySummary(day: day, score: ScreenScoreTotals(completed: 1, opportunities: 1)),
                    DailySummary(day: "2026-10-03", score: ScreenScoreTotals(completed: 1, opportunities: 3)),
                    DailySummary(day: "2026-10-02", breaks: 20, shortBreaks: 20)]
        let snapshot = StatisticsSnapshot(days: rows, period: 7, today: day, language: "tr")
        #expect(snapshot.score?.percent == 50)
        #expect(snapshot.byDay["2026-10-02"]?.score == nil)
        #expect(snapshot.score?.opportunities == 4)
    }
    @Test func oldDaysRemainWithoutScoresAndRoundTripPreservesNewTotals() throws {
        let old = Data(#"{"version":1,"enabled":true,"weekly":false,"retention":90,"days":[{"day":"2026-10-04","active":0,"video":0,"watching":0,"observed":0,"breaks":2,"eyes":2,"movement":1,"natural":0,"rest":140}]}"#.utf8)
        var d = try StatisticsCodec.decode(old)
        #expect(d.days[0].score == nil)
        d.days[0].score = ScreenScoreTotals(completed: 2, opportunities: 3)
        #expect(try StatisticsCodec.decode(JSONEncoder().encode(d)).days == d.days)
        #expect(d.days[0].eyes == 2 && d.days[0].movement == 1)
    }
    @Test func malformedScoreCountsAreRejected() throws {
        for value in [ScreenScoreTotals(completed: -1, opportunities: 3),
                      ScreenScoreTotals(completed: 4, opportunities: 3),
                      ScreenScoreTotals(completed: 0, opportunities: -1),
                      ScreenScoreTotals(completed: 0, opportunities: 8641)] {
            var d = StatisticsDocument(); d.days = [DailySummary(day: day, score: value)]
            #expect(throws: (any Error).self) { try StatisticsCodec.decode(JSONEncoder().encode(d)) }
        }
        let base = try JSONEncoder().encode(StatisticsDocument(days: [DailySummary(day: day)]))
        var object = try #require(JSONSerialization.jsonObject(with: base) as? [String: Any])
        var rows = try #require(object["days"] as? [[String: Any]])
        for bad: [String: Any] in [["completed": 1], ["completed": true, "opportunities": 3], ["completed": 0, "opportunities": "3"]] {
            rows[0]["score"] = bad; object["days"] = rows
            #expect(throws: (any Error).self) { try StatisticsCodec.decode(JSONSerialization.data(withJSONObject: object)) }
        }
    }
    @Test func pendingRollbackAndRepeatedObservationNeverResolveThemselves() {
        var cycle = ScreenScoreCycle(); cycle.start(fromBeginning: true)
        for _ in 0..<10 { cycle.observe(confirmedDue: true) }
        cycle.observe(confirmedDue: false)
        #expect(cycle.resolve(completed: true) == nil)
        cycle.observe(confirmedDue: true)
        #expect(cycle.resolve(completed: false) == false)
        #expect(cycle.resolve(completed: true) == nil)
        cycle.start(fromBeginning: false); cycle.observe(confirmedDue: true)
        #expect(cycle.resolve(completed: true) == nil)
    }
    @Test func dueManualAndNaturalCompletionsCountOnceAndSkipCountsOnce() throws {
        try withModel { m, _ in
            due(m); complete(m)
            #expect(score(m) == ScreenScoreTotals(completed: 1, opportunities: 1))
            due(m)
            m.resumeTracking(after: Double(m.config.shortRestSeconds))
            #expect(score(m) == ScreenScoreTotals(completed: 2, opportunities: 2))
            due(m); #expect(m.skipBreak(now: 100))
            #expect(score(m) == ScreenScoreTotals(completed: 2, opportunities: 3))
            #expect(score(m)?.percent == 67)
            m.resumeTracking(after: 1000)
            #expect(score(m)?.opportunities == 3)
        }
    }
    @Test func arbitraryTimingAndLongCadenceDoNotCreateFixedIntervalScores() throws {
        try withModel { m, _ in
            m.settings.update { $0.workMinutes = 45; $0.shortBreaksBeforeLong = 1 }
            due(m); complete(m)
            #expect(m.nextKind == .long)
            due(m); complete(m)
            due(m); complete(m)
            #expect(score(m) == ScreenScoreTotals(completed: 3, opportunities: 3))
            #expect(score(m)?.percent == 100)
        }
    }
    @Test func extraEarlyManualAndNaturalBreaksDoNotInflateScore() throws {
        try withModel { m, _ in
            for _ in 0..<5 { complete(m) }
            m.resumeTracking(after: 1000)
            #expect(score(m) == nil)
            due(m); complete(m)
            for _ in 0..<5 { complete(m) }
            #expect(score(m) == ScreenScoreTotals(completed: 1, opportunities: 1))
            #expect(m.statistics.days.reduce(0) { $0 + $1.breaks } == 11)
        }
    }
    @Test func snoozesRetriesEarlyReturnsAndClosingHaveNoRepeatedPenalty() throws {
        try withModel { m, _ in
            due(m)
            for _ in 0..<4 { m.snoozeReminder(); m.reminderKinds = [m.nextKind] }
            m.dismissReminder(); #expect(score(m) == nil)
            m.beginRest(.short, now: 100); m.cancelRest()
            #expect(score(m) == nil)
            complete(m)
            #expect(score(m) == ScreenScoreTotals(completed: 1, opportunities: 1))
        }
    }
    @Test func optInMidCycleAndTimingEditDoNotReconstructOpportunities() throws {
        try withModel { m, _ in
            m.setStatisticsEnabled(false); due(m); m.setStatisticsEnabled(true); complete(m)
            #expect(score(m) == nil)
            due(m); complete(m)
            #expect(score(m)?.opportunities == 1)
            due(m); m.settings.update { $0.workMinutes = 45 }; complete(m)
            #expect(score(m)?.opportunities == 1)
            due(m); complete(m)
            #expect(score(m)?.opportunities == 2)
        }
    }
    @Test func quietAndTypingAreNotFailuresAndPreviewIsIsolated() throws {
        try withModel { m, _ in
            m.togglePresentation(); due(m)
            m.previewReminder(); m.dismissReminder()
            #expect(score(m) == nil)
            m.togglePresentation(); m.previewReminder()
            #expect(!m.skipBreak(now: 1000))
            m.dismissReminder(); complete(m)
            #expect(score(m) == ScreenScoreTotals(completed: 1, opportunities: 1))
        }
    }
    @Test func pauseAndSleepPreservePendingWithoutSavingFailure() throws {
        try withModel { m, _ in
            m.toggleWatching() // Keep uncontrolled physical idle out of this synthetic lifecycle check.
            due(m); m.pauseTracking(.untilResumed)
            #expect(score(m) == nil)
            m.resumeManualPause(); m.suspendTracking()
            #expect(score(m) == nil)
            m.resumeTracking(after: Double(m.config.shortRestSeconds))
            #expect(score(m) == ScreenScoreTotals(completed: 1, opportunities: 1))
        }
    }
    @Test func consentDeletionRelaunchAndRetentionBoundScoreData() throws {
        try withModel { m, directory in
            due(m); complete(m); due(m); m.statistics.flush()
            let reopened = StatisticsStore(url: directory.appendingPathComponent("statistics.json"))
            #expect(ScreenScoreTotals.combining(reopened.days)?.opportunities == 1)
            reopened.resolveScoreOpportunity(completed: false)
            #expect(ScreenScoreTotals.combining(reopened.days)?.opportunities == 1)
            m.setStatisticsEnabled(false); complete(m)
            #expect(score(m)?.opportunities == 1)
            m.clearStatistics(); #expect(score(m) == nil && !m.statistics.enabled)
            var l = StatisticsLedger(); l.document.enabled = true; l.document.retention = 30
            l.recordScore(day: "2026-08-01", completed: true); l.recordScore(day: day, completed: false)
            l.prune(today: day); #expect(l.document.days.count == 1 && l.document.days[0].score?.completed == 0)
        }
    }
    @Test func noConsentAndCorruptionNeverCreateOrOverwriteScoreData() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("stats.json")
        let s = StatisticsStore(url: url)
        s.startScoreCycle(fromBeginning: true); s.observeScoreOpportunity(confirmedDue: true)
        s.resolveScoreOpportunity(completed: true); s.flush()
        #expect(s.days.isEmpty && !FileManager.default.fileExists(atPath: url.path))
        let original = Data("broken".utf8); try original.write(to: url)
        let broken = StatisticsStore(url: url)
        broken.setEnabled(true); broken.startScoreCycle(fromBeginning: true)
        broken.observeScoreOpportunity(confirmedDue: true); broken.resolveScoreOpportunity(completed: false)
        let after = try Data(contentsOf: url)
        #expect(broken.failed && after == original)
        let backup = String(data: try SettingsCodec.export(AppSettings()), encoding: .utf8)!
        #expect(!backup.contains("score") && !backup.contains("opportunities"))
    }
    @Test func provisionalIdleCrossingDeadlineDoesNotCreateAScore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        final class Wall { var now = Date() }
        let wall = Wall(), settings = SettingsStore(url: directory.appendingPathComponent("settings.json"))
        settings.update { $0.workMinutes = 5; $0.idlePauseSeconds = 30; $0.videoEnabled = false }
        let m = AppContainer(settings: settings, statistics: StatisticsStore(url: directory.appendingPathComponent("stats.json")), wallClock: { wall.now })
        defer { m.stop() }
        m.setStatisticsEnabled(true)
        for tick in 0..<290 {
            wall.now = wall.now.addingTimeInterval(1)
            m.tick(now: Double(tick), idle: 0, deliberateIdle: .infinity)
        }
        for idle in 1...30 {
            wall.now = wall.now.addingTimeInterval(1)
            m.tick(now: Double(289 + idle), idle: Double(idle), deliberateIdle: .infinity)
        }
        #expect(m.breakEngine.workAccrued == 0) // qualifying natural rest reset the cycle
        #expect(score(m) == nil)
    }
    @Test func dailyOutcomeAttributionAndClockDiscontinuity() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("stats.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let now = StatsCalendar.date(day)!.addingTimeInterval(12 * 3600)
        let s = StatisticsStore(url: url, now: now); s.setEnabled(true, now: now); s.startScoreCycle(fromBeginning: true)
        s.observeScoreOpportunity(confirmedDue: true)
        s.resolveScoreOpportunity(completed: true, now: now.addingTimeInterval(86_400))
        #expect(s.days.last?.day == "2026-10-05" && s.days.last?.score?.opportunities == 1)
        s.sample(now: now.addingTimeInterval(86_400), uptime: 1, active: 1, rollback: 0, provisional: 0, observed: 1, video: false, watching: false)
        s.observeScoreOpportunity(confirmedDue: true)
        s.sample(now: now.addingTimeInterval(90_000), uptime: 2, active: 1, rollback: 0, provisional: 0, observed: 1, video: false, watching: false)
        s.resolveScoreOpportunity(completed: false, now: now.addingTimeInterval(90_000))
        #expect(ScreenScoreTotals.combining(s.days)?.opportunities == 1)
    }
}
