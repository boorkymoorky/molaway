import Foundation
import Testing
@testable import Offscreen

@Suite @MainActor struct StatisticsTests {
    let day = "2026-09-24"
    func enabled() -> StatisticsLedger { var value = StatisticsLedger(); value.document.enabled = true; return value }
    func temp() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("statistics.json") }
    @Test func noConsentMeansNoDataOrFile() throws {
        let url = temp(); let store = StatisticsStore(url: url)
        store.sample(now: Date(), uptime: 100, active: 5, rollback: 0, provisional: 0, observed: 5, video: true, watching: true)
        store.flush(); #expect(!store.enabled); #expect(store.days.isEmpty); #expect(!FileManager.default.fileExists(atPath: url.path))
    }
    @Test func provisionalIdleNeverReachesSavedTotals() {
        var l = enabled()
        l.sample(day: day, active: 5, rollback: 0, provisional: 5, observed: 5, video: false, watching: false)
        #expect(l.document.days[0].active == 0)
        l.sample(day: day, active: 0, rollback: 5, provisional: 0, observed: 1, video: false, watching: false)
        #expect(l.document.days[0].active == 0)
    }
    @Test func confirmationPreservesMidnightAttribution() {
        var l = enabled()
        l.sample(day: "2026-09-23", active: 5, rollback: 0, provisional: 5, observed: 5, video: false, watching: false)
        l.sample(day: day, active: 3, rollback: 0, provisional: 0, observed: 3, video: false, watching: false)
        #expect(l.document.days[0].active == 5); #expect(l.document.days[1].active == 3)
    }
    @Test func videoIsSubsetAndManualWatchingDoesNotDoubleCount() {
        var l = enabled()
        l.sample(day: day, active: 5, rollback: 0, provisional: 0, observed: 5, video: true, watching: true)
        l.sample(day: day, active: 3, rollback: 0, provisional: 0, observed: 3, video: false, watching: true)
        let row = l.document.days[0]
        #expect(row.active == 8); #expect(row.video == 5); #expect(row.watching == 3); #expect(row.valid)
    }
    @Test func absenceAtLaunchDoesNotInventBreaks() {
        var l = enabled(); l.naturalCycle(day: day, kind: .short, target: 20)
        #expect(l.document.days.isEmpty)
    }
    @Test func continuousNaturalBreakCountsOnce() {
        var l = enabled()
        l.sample(day: day, active: 1, rollback: 0, provisional: 0, observed: 1, video: false, watching: false)
        l.naturalCycle(day: day, kind: .short, target: 20)
        l.naturalCycle(day: day, kind: .long, target: 120)
        let row = l.document.days[0]
        #expect(row.breaks == 1 && row.shortBreaks == 1 && row.longBreaks == 0 && row.natural == 1 && row.rest == 20)
    }
    @Test func returningThenLeavingMakesANewNaturalBreak() {
        var l = enabled()
        for _ in 0..<2 {
            l.sample(day: day, active: 1, rollback: 0, provisional: 0, observed: 1, video: false, watching: false)
            l.naturalCycle(day: day, kind: .short, target: 20)
        }
        #expect(l.document.days[0].breaks == 2)
    }
    @Test func cancelledAndUnstartedManualBreaksDoNotCount() {
        var l = enabled(); l.completeCycle(day: day, kind: .long, duration: 120)
        l.beginManual(); l.cancelManual(); l.completeCycle(day: day, kind: .long, duration: 120)
        #expect(l.document.days.isEmpty)
    }
    @Test func completedLongCountsOnce() {
        var l = enabled(); l.beginManual(); l.completeCycle(day: day, kind: .long, duration: 120)
        l.completeCycle(day: day, kind: .long, duration: 120)
        let row = l.document.days[0]
        #expect(row.breaks == 1 && row.shortBreaks == 0 && row.longBreaks == 1 && row.rest == 120)
    }
    @Test func manualBreakIsNotAlsoCreditedAsNatural() {
        var l = enabled(); l.sample(day: day, active: 5, rollback: 0, provisional: 0, observed: 5, video: false, watching: false)
        l.beginManual(); l.completeCycle(day: day, kind: .short, duration: 20)
        l.naturalCycle(day: day, kind: .short, target: 20)
        #expect(l.document.days[0].breaks == 1)
    }
    @Test func legacyCountsKeepOriginalMeaning() throws {
        let old = Data(#"{"version":1,"enabled":true,"weekly":false,"retention":90,"days":[{"day":"2026-09-24","active":0,"video":0,"watching":0,"observed":0,"breaks":2,"eyes":2,"movement":1,"natural":0,"rest":140}]}"#.utf8)
        var document = try StatisticsCodec.decode(old)
        #expect(document.days[0].eyes == 2 && document.days[0].movement == 1)
        #expect(document.days[0].shortBreaks == 0 && document.days[0].longBreaks == 0)
        var ledger = StatisticsLedger(); ledger.document = document
        ledger.beginManual(); ledger.completeCycle(day: day, kind: .short, duration: 20)
        document = ledger.document
        #expect(document.days[0].eyes == 2 && document.days[0].movement == 1)
        #expect(document.days[0].shortBreaks == 1 && document.days[0].breaks == 3)
        #expect(try StatisticsCodec.decode(JSONEncoder().encode(document)).days[0] == document.days[0])
    }
    @Test func continuedInactivityAfterManualBreakDoesNotInventAnotherBreak() {
        var l = enabled(); l.beginManual(); l.completeCycle(day: day, kind: .short, duration: 20)
        l.sample(day: day, active: 5, rollback: 0, provisional: 5, observed: 5, video: false, watching: false)
        l.sample(day: day, active: 0, rollback: 5, provisional: 0, observed: 1, video: false, watching: false)
        l.naturalCycle(day: day, kind: .short, target: 20)
        #expect(l.document.days[0].breaks == 1)
    }
    @Test func invalidSamplesAreIgnored() {
        var l = enabled()
        l.sample(day: day, active: .infinity, rollback: 0, provisional: 0, observed: 1, video: true, watching: false)
        l.sample(day: day, active: 1000, rollback: 0, provisional: 0, observed: 1000, video: true, watching: false)
        #expect(l.document.days.isEmpty)
    }
    @Test func retentionAndInvalidCalendarDates() {
        var l = enabled(); l.document.retention = 30
        l.document.days = [DailySummary(day: "2026-08-25"), DailySummary(day: "2026-08-26"), DailySummary(day: day), DailySummary(day: "2027-01-01")]
        l.prune(today: day); #expect(l.document.days.map(\.day) == ["2026-08-26", day])
        #expect(StatsCalendar.date("2026-02-30") == nil); #expect(StatsCalendar.date("../../../a") == nil)
        #expect(StatsCalendar.shifted("2024-03-01", days: -1) == "2024-02-29")
    }
    @Test func codecRejectsBadBoundsDuplicatesVersionsAndHugeFiles() throws {
        var d = StatisticsDocument(); d.days = [DailySummary(day: day, active: 1, video: 2)]
        #expect(throws: (any Error).self) { try StatisticsCodec.decode(JSONEncoder().encode(d)) }
        d.days = [DailySummary(day: day), DailySummary(day: day)]
        #expect(throws: (any Error).self) { try StatisticsCodec.decode(JSONEncoder().encode(d)) }
        d.days = []; d.version = 8
        #expect(throws: (any Error).self) { try StatisticsCodec.decode(JSONEncoder().encode(d)) }
        #expect(throws: (any Error).self) { try StatisticsCodec.decode(Data(repeating: 32, count: StatisticsCodec.maximumBytes + 1)) }
    }
    @Test func symlinksAndDirectoriesAreRejected() throws {
        let url = temp(); try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let other = url.appendingPathExtension("original"); try JSONEncoder().encode(StatisticsDocument()).write(to: other)
        try FileManager.default.createSymbolicLink(at: url, withDestinationURL: other)
        #expect(throws: (any Error).self) { try StatisticsCodec.read(url) }
        #expect(throws: (any Error).self) { try StatisticsCodec.read(url.deletingLastPathComponent()) }
    }
    @Test func optOutClearsPendingAndKeepsOldDataThenEraseDisables() throws {
        let url = temp(); defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let now = StatsCalendar.date(day)!.addingTimeInterval(3600), s = StatisticsStore(url: url, now: now)
        s.setEnabled(true, now: now)
        s.sample(now: now, uptime: 20, active: 5, rollback: 0, provisional: 0, observed: 5, video: true, watching: false)
        s.setWeekly(true, now: now); s.setEnabled(false, now: now)
        #expect(!s.enabled && !s.weekly && s.days[0].active == 5)
        #expect(try StatisticsCodec.read(url).days[0].active == 5)
        s.clear(); #expect(s.days.isEmpty && !s.enabled && !s.weekly)
        #expect(try StatisticsCodec.read(url).days.isEmpty)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o600)
    }
    @Test func failedReplacementKeepsOriginalFile() throws {
        let url = temp(); defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let d = StatisticsDocument(); try StatisticsCodec.write(d, to: url)
        let before = try Data(contentsOf: url)
        var invalid = d; invalid.version = 99
        #expect(throws: (any Error).self) { try StatisticsCodec.write(invalid, to: url) }
        #expect(try Data(contentsOf: url) == before)
    }
    @Test func corruptStoreDoesNotOverwriteUntilExplicitReset() throws {
        let url = temp(); try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let original = Data("corrupt".utf8); try original.write(to: url)
        let s = StatisticsStore(url: url); s.setEnabled(true); s.flush()
        #expect(s.failed && !s.enabled); #expect(try Data(contentsOf: url) == original)
        s.clear(); #expect(!s.failed); #expect(try StatisticsCodec.read(url).days.isEmpty)
    }
    @Test func disabledHistoryIsPrunedOnLoadAndSaved() throws {
        let url = temp(); try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        var d = StatisticsDocument(); d.days = [DailySummary(day: "2020-01-01")]
        try JSONEncoder().encode(d).write(to: url)
        let s = StatisticsStore(url: url); #expect(!s.enabled && s.days.isEmpty)
        #expect(try StatisticsCodec.read(url).days.isEmpty)
    }
    @Test func clockJumpDoesNotAddUsage() {
        let url = temp(); defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let now = StatsCalendar.date(day)!, s = StatisticsStore(url: url, now: now); s.setEnabled(true, now: now)
        s.sample(now: now, uptime: 20, active: 1, rollback: 0, provisional: 0, observed: 1, video: false, watching: false)
        s.sample(now: now.addingTimeInterval(3600), uptime: 21, active: 5, rollback: 0, provisional: 0, observed: 5, video: false, watching: false)
        s.setEnabled(false, now: now); #expect(s.days.reduce(0) { $0 + $1.active } == 1)
    }
    @Test func comparisonNeedsEnoughCompleteDaysAndExcludesToday() {
        var rows = StatsCalendar.recent(14, today: day, includeToday: false).map { DailySummary(day: $0, active: 3600, observed: 4000) }
        rows.append(DailySummary(day: day, active: 86_400, observed: 86_400))
        let c = StatisticsComparison.make(days: rows, period: 7, today: day)
        #expect(c?.percent == 0); #expect(c?.currentDays == 7)
        #expect(StatisticsComparison.make(days: Array(rows.suffix(4)), period: 7, today: day) == nil)
    }
    @Test func weeklyRequiresConsentEnoughDataAndSevenDays() throws {
        let url = temp(); try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let now = StatsCalendar.date(day)!
        var d = StatisticsDocument(); d.enabled = true; d.weekly = true; d.lastReportDay = "2026-09-17"
        d.days = StatsCalendar.recent(7, today: day, includeToday: false).map { DailySummary(day: $0, active: 600, observed: 900) }
        try JSONEncoder().encode(d).write(to: url)
        let s = StatisticsStore(url: url, now: now); #expect(s.reportDue(now: now))
        s.reportAttempted(now: now); #expect(!s.reportDue(now: now.addingTimeInterval(1)))
        s.reportDelivered(now: now); #expect(!s.reportDue(now: now.addingTimeInterval(86_400)))
        s.setEnabled(false, now: now); #expect(!s.reportDue(now: now.addingTimeInterval(8 * 86_400)))
    }
    @Test func weeklyAttemptSurvivesRelaunchWithoutDuplicate() throws {
        let url = temp(); defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let now = StatsCalendar.date(day)!
        let s = StatisticsStore(url: url, now: now); s.setEnabled(true, now: now); s.setWeekly(true, now: now)
        s.reportAttempted(now: now)
        #expect(try StatisticsCodec.read(url).lastReportDay == day)
        let reloaded = StatisticsStore(url: url, now: now)
        #expect(!reloaded.reportDue(now: now.addingTimeInterval(60)))
    }
    @Test func overdueNeedsTimeAndExplicitSnoozes() {
        #expect(OverdueLevel.evaluate(enabled: true, overdue: 599, snoozes: 10, amberMinutes: 10, redMinutes: 20) == .normal)
        #expect(OverdueLevel.evaluate(enabled: true, overdue: 1200, snoozes: 2, amberMinutes: 10, redMinutes: 20) == .amber)
        #expect(OverdueLevel.evaluate(enabled: true, overdue: 1200, snoozes: 3, amberMinutes: 10, redMinutes: 20) == .red)
        #expect(OverdueLevel.evaluate(enabled: false, overdue: 6000, snoozes: 10, amberMinutes: 10, redMinutes: 20) == .normal)
    }
    @Test func automaticDeferralDoesNotCountAndQualifiedRestResets() {
        let e = BreakEngine(); e.gentleReminders = true; e.advance(by: 2000); e.deferReminder()
        #expect(e.explicitDeferrals == 0)
        e.recordExplicitDeferral(); e.recordExplicitDeferral(); #expect(e.explicitDeferrals == 2)
        e.accountForNaturalRest(1); #expect(e.explicitDeferrals == 2)
        e.accountForNaturalRest(20); #expect(e.explicitDeferrals == 0)
    }
    @Test func overdueSettingBoundsAndLegacyDefaults() throws {
        let old = try SettingsCodec.decode(Data("{}".utf8)); #expect(old.overdueEnabled && old.amberMinutes == 10 && old.redMinutes == 20)
        var s = old; s.amberMinutes = Int.max; s.redMinutes = Int.min; s.validate()
        #expect(s.amberMinutes == 60 && s.redMinutes == 65)
        let exported = String(data: try SettingsCodec.export(s), encoding: .utf8)!
        #expect(!exported.contains("statistics")); #expect(!exported.contains("weekly"))
    }
    @Test func strictCalendarParsingAndYearBoundaries() {
        for key in ["2026-2-03", "2026-00-01", "2026-13-01", "2026-01-00", "2026-04-31", "2025-02-29", "0000-01-01", "２０２６-01-01", "2026/01/01"] {
            #expect(StatsCalendar.date(key) == nil)
        }
        #expect(StatsCalendar.shifted("2026-01-01", days: -1) == "2025-12-31")
        #expect(StatsCalendar.recent(3, today: "2024-03-01") == ["2024-02-28", "2024-02-29", "2024-03-01"])
    }
    @Test func chartSnapshotPreservesMissingDaysAndPeriodTotals() {
        let days = [DailySummary(day: "2026-09-23", active: 3600, breaks: 2, eyes: 2, rest: 40),
                    DailySummary(day: day), DailySummary(day: "2026-09-01", active: 7200)]
        let week = StatisticsSnapshot(days: days, period: 7, today: day, language: "en")
        let month = StatisticsSnapshot(days: days, period: 30, today: day, language: "en")
        #expect(week.keys.count == 7 && week.rows.count == 2)
        #expect(week.byDay[day]?.active == 0 && week.byDay["2026-09-22"] == nil)
        #expect(week.totals.active == 3600 && week.totals.breaks == 2 && week.totals.rest == 40)
        #expect(month.totals.active == 10800 && month.rows.count == 3)
        #expect(week.axisKeys == week.keys)
        #expect(week.labels[day]?.contains("Sep") == true)
        let tr = StatisticsSnapshot(days: days, period: 90, today: day, language: "tr")
        #expect(tr.keys.count == 90 && tr.labels[day]?.contains("Eyl") == true)
    }
    @Test func fullHistoryChartPreparationBenchmark() {
        let rows = StatsCalendar.recent(90, today: day).map { DailySummary(day: $0, active: 3600, observed: 4000) }
        let start = Date()
        for _ in 0..<10 {
            for period in [7, 30, 90] {
                let value = StatisticsSnapshot(days: rows, period: period, today: day, language: "en")
                #expect(value.rows.count == period && value.totals.active == Double(period) * 3600)
            }
        }
        print("30 complete chart snapshots: \(Date().timeIntervalSince(start)) seconds (data preparation only)")
    }

}
