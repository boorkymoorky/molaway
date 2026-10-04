import Foundation
import Observation

@Observable final class StatisticsStore {
    private(set) var days: [DailySummary] = []
    private(set) var enabled = false
    private(set) var weekly = false
    private(set) var retention = 90
    private(set) var failed = false
    @ObservationIgnored private var ledger = StatisticsLedger()
    @ObservationIgnored private var scoreCycle = ScreenScoreCycle()
    @ObservationIgnored private let url: URL
    @ObservationIgnored private var dirty = false
    @ObservationIgnored private var lastSave = 0.0
    @ObservationIgnored private var lastPublish = 0.0
    @ObservationIgnored private var lastDay = ""
    @ObservationIgnored private var lastDate: Date?
    @ObservationIgnored private var nextReportAttempt: Date = .distantPast

    init(url: URL = SettingsStore.directoryURL.appendingPathComponent("statistics.json"), now: Date = Date()) {
        self.url = url
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                ledger.document = try StatisticsCodec.read(url)
                let old = ledger.document.days; ledger.prune(today: StatsCalendar.key(now)); dirty = old != ledger.document.days
            }
            catch { failed = true }
        }
        lastDay = StatsCalendar.key(now); publish(); flush()
    }
    func setEnabled(_ value: Bool, now: Date = Date()) {
        guard !failed else { return }
        scoreCycle.start(fromBeginning: false)
        ledger.resetSession(); ledger.document.enabled = value
        if !value { ledger.document.weekly = false }
        ledger.document.lastReportDay = StatsCalendar.key(now)
        changed()
    }
    func setWeekly(_ value: Bool, now: Date = Date()) {
        guard !failed else { return }
        ledger.document.weekly = value && enabled; ledger.document.lastReportDay = StatsCalendar.key(now); changed()
    }
    func setRetention(_ value: Int, now: Date = Date()) {
        guard [30,90].contains(value), !failed else { return }
        ledger.document.retention = value; ledger.prune(today: StatsCalendar.key(now)); changed()
    }
    func clear() {
        scoreCycle.start(fromBeginning: false)
        ledger = StatisticsLedger(); failed = false; lastDate = nil; lastDay = ""; changed()
    }
    private func publish() {
        days = ledger.document.days.sorted { $0.day < $1.day }; enabled = ledger.document.enabled
        weekly = ledger.document.weekly; retention = ledger.document.retention
    }
    private func changed() { dirty = true; publish(); flush() }
    func flush() {
        guard dirty, !failed else { return }
        do {
            try StatisticsCodec.write(ledger.document, to: url)
            dirty = false
        } catch { failed = true; ledger.resetSession(); scoreCycle.start(fromBeginning: false); publish() }
    }
    func sample(now: Date, uptime: Double, active: Double, rollback: Double, provisional: Double, observed: Double, video: Bool, watching: Bool) {
        guard !failed else { return }
        let day = StatsCalendar.key(now)
        if day != lastDay { ledger.prune(today: day); lastDay = day; dirty = true; publish(); flush() }
        guard enabled else { return }
        if let previous = lastDate, abs(now.timeIntervalSince(previous) - observed) > 60 {
            ledger.resetSession(); scoreCycle.start(fromBeginning: false); lastDate = now; return
        }
        lastDate = now
        // Attribute a boundary-spanning sample to its start day; uncertainty is at most 5 seconds.
        let sampleDay = StatsCalendar.key(now.addingTimeInterval(-max(active, observed)))
        ledger.sample(day: sampleDay, active: active, rollback: rollback, provisional: provisional, observed: observed, video: video, watching: watching)
        dirty = true
        if uptime - lastPublish >= 15 { publish(); lastPublish = uptime }
        if uptime - lastSave >= 60 { flush(); lastSave = uptime }
    }
    func startScoreCycle(fromBeginning: Bool) {
        scoreCycle.start(fromBeginning: fromBeginning && enabled && !failed)
    }
    func observeScoreOpportunity(confirmedDue: Bool) {
        guard enabled, !failed else { return }
        scoreCycle.observe(confirmedDue: confirmedDue)
    }
    func resolveScoreOpportunity(completed: Bool, now: Date = Date()) {
        guard enabled, !failed else { return }
        guard let result = scoreCycle.resolve(completed: completed) else { return }
        let day = StatsCalendar.key(now)
        ledger.prune(today: day)
        ledger.recordScore(day: day, completed: result)
        changed()
    }
    func beginManual() { guard !failed else { return }; ledger.beginManual() }
    func cancelManual() { ledger.cancelManual() }
    func completeCycle(kind: MolaKind, duration: Double, now: Date = Date()) {
        guard enabled, !failed else { return }
        ledger.completeCycle(day: StatsCalendar.key(now), kind: kind, duration: duration); changed()
    }
    func naturalCycle(kind: MolaKind, target: Double, now: Date = Date()) {
        guard enabled, !failed else { return }
        ledger.naturalCycle(day: StatsCalendar.key(now), kind: kind, target: target); changed()
    }
    func resetSession() { ledger.resetSession(); lastDate = nil }
    func reportDue(now: Date = Date()) -> Bool {
        guard enabled, weekly, !failed, now >= nextReportAttempt else { return false }
        let today = StatsCalendar.key(now), keys = Set(StatsCalendar.recent(7, today: StatsCalendar.key(now), includeToday: false))
        return (ledger.document.lastReportDay ?? today) <= StatsCalendar.shifted(today, days: -7)
            && ledger.document.days.filter { $0.observed >= 60 && $0.day < today }.count >= 7
            && ledger.document.days.filter { keys.contains($0.day) && $0.observed >= 60 }.count >= 3
    }
    func reportAttempted(now: Date = Date()) {
        // Persist before dispatch: relaunching during delivery must not send another summary.
        nextReportAttempt = now.addingTimeInterval(86_400)
        ledger.document.lastReportDay = StatsCalendar.key(now); changed()
    }
    func reportDelivered(now: Date = Date()) { ledger.document.lastReportDay = StatsCalendar.key(now); changed() }
}
