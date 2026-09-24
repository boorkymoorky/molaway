import Foundation
import Darwin

struct DailySummary: Codable, Equatable, Identifiable, Sendable {
    var day: String
    var active: Double = 0
    var video: Double = 0
    var watching: Double = 0
    var observed: Double = 0
    var breaks: Int = 0
    var eyes: Int = 0
    var movement: Int = 0
    var natural: Int = 0
    var rest: Double = 0
    var id: String { day }
    var valid: Bool {
        StatsCalendar.date(day) != nil && [active, video, watching, observed, rest].allSatisfy { $0.isFinite && (0...86_400).contains($0) }
        && video + watching <= active + 0.01 && [breaks, eyes, movement, natural].allSatisfy { (0...8640).contains($0) }
        && eyes <= breaks && movement <= breaks && natural <= breaks
    }
}
struct StatisticsDocument: Codable, Sendable {
    var version = 1
    var enabled = false
    var weekly = false
    var retention = 90
    var lastReportDay: String?
    var days: [DailySummary] = []
}
enum StatsCalendar {
    static func key(_ date: Date, calendar: Calendar = .current) -> String {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = calendar.timeZone
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
    static func date(_ key: String) -> Date? {
        let bytes = Array(key.utf8)
        guard bytes.count == 10, bytes[4] == 45, bytes[7] == 45,
              bytes.enumerated().allSatisfy({ $0.offset == 4 || $0.offset == 7 || (48...57).contains($0.element) }) else { return nil }
        let year = Int(bytes[0] - 48) * 1000 + Int(bytes[1] - 48) * 100 + Int(bytes[2] - 48) * 10 + Int(bytes[3] - 48)
        let month = Int(bytes[5] - 48) * 10 + Int(bytes[6] - 48)
        let day = Int(bytes[8] - 48) * 10 + Int(bytes[9] - 48)
        guard year >= 1, (1...12).contains(month), (1...31).contains(day) else { return nil }
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let date = cal.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }
        let actual = cal.dateComponents([.year, .month, .day], from: date)
        guard actual.year == year, actual.month == month, actual.day == day else { return nil }
        return date
    }
    static func shifted(_ key: String, days: Int) -> String {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let date = date(key), let shifted = cal.date(byAdding: .day, value: days, to: date) else { return key }
        return self.key(shifted, calendar: cal)
    }
    static func recent(_ count: Int, today: String, includeToday: Bool = true) -> [String] {
        (0..<count).reversed().map { shifted(today, days: -$0 - (includeToday ? 0 : 1)) }
    }
}
enum StatisticsCodec {
    static let maximumBytes = 524_288
    static func decode(_ data: Data) throws -> StatisticsDocument {
        guard data.count <= maximumBytes else { throw SettingsError.size }
        let value = try JSONDecoder().decode(StatisticsDocument.self, from: data)
        guard value.version == 1, [30, 90].contains(value.retention), value.days.count <= 90,
              Set(value.days.map(\.day)).count == value.days.count, value.days.allSatisfy(\.valid),
              value.lastReportDay.map({ StatsCalendar.date($0) != nil }) ?? true else { throw SettingsError.fields }
        return value
    }
    static func write(_ value: StatisticsDocument, to url: URL) throws {
        let data = try JSONEncoder().encode(value)
        _ = try decode(data)
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let temp = directory.appendingPathComponent(".summary-" + UUID().uuidString)
        let fd = open(temp.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
        guard fd >= 0 else { throw SettingsError.file }
        let file = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer { try? file.close(); unlink(temp.path) }
        try file.write(contentsOf: data)
        try file.synchronize()
        guard rename(temp.path, url.path) == 0 else { throw SettingsError.file }
    }
    static func read(_ url: URL) throws -> StatisticsDocument {
        let fd = open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard fd >= 0 else { throw SettingsError.file }
        let file = FileHandle(fileDescriptor: fd, closeOnDealloc: true); defer { try? file.close() }
        var meta = stat()
        guard fstat(fd, &meta) == 0, meta.st_mode & S_IFMT == S_IFREG else { throw SettingsError.file }
        guard meta.st_size >= 0, meta.st_size <= maximumBytes else { throw SettingsError.size }
        return try decode(try file.read(upToCount: maximumBytes + 1) ?? Data())
    }
}

/// Only day-level amounts are persisted. Provisional idle time stays in memory.
struct StatisticsLedger {
    struct Slice { var day: String; var seconds: Double; var video: Bool; var watching: Bool }
    var document = StatisticsDocument()
    private var pending: [Slice] = []
    private var naturalKinds: Set<MolaKind> = []
    private var naturalSeconds: Double = 0
    private var naturalDay: String?
    private var eligibleNatural = false
    private var manualStarted = false

    mutating func resetSession() { pending.removeAll(); naturalKinds.removeAll(); naturalSeconds = 0; naturalDay = nil; eligibleNatural = false; manualStarted = false }
    mutating func prune(today: String) {
        let cutoff = StatsCalendar.shifted(today, days: 1 - document.retention)
        document.days.removeAll { $0.day < cutoff || $0.day > today }
        if document.lastReportDay.map({ $0 > today }) == true { document.lastReportDay = today }
    }
    private mutating func edit(_ day: String, _ change: (inout DailySummary) -> Void) {
        if let index = document.days.firstIndex(where: { $0.day == day }) { change(&document.days[index]) }
        else { var row = DailySummary(day: day); change(&row); document.days.append(row) }
    }
    mutating func sample(day: String, active: Double, rollback: Double, provisional: Double, observed: Double, video: Bool, watching: Bool) {
        guard document.enabled else { return }
        guard [active, rollback, provisional, observed].allSatisfy({ $0.isFinite && $0 >= 0 }), active <= 5, observed <= 5 else { return }
        if observed > 0 { edit(day) { $0.observed = min(86_400, $0.observed + observed) } }
        if active > 0 {
            pending.append(Slice(day: day, seconds: active, video: video, watching: watching && !video))
        }
        var remove = rollback
        while remove > 0, let last = pending.last {
            let amount = min(remove, last.seconds); remove -= amount
            if amount >= last.seconds { pending.removeLast() } else { pending[pending.count - 1].seconds -= amount }
        }
        var commit = max(0, pending.reduce(0) { $0 + $1.seconds } - provisional)
        while commit > 0.000_001, let first = pending.first {
            let amount = min(commit, first.seconds); commit -= amount
            if !naturalKinds.isEmpty { naturalKinds.removeAll(); naturalSeconds = 0; naturalDay = nil }
            eligibleNatural = true
            edit(first.day) { row in
                let room = min(amount, max(0, 86_400 - row.active)); row.active += room
                if first.video { row.video += room }; if first.watching { row.watching += room }
            }
            if amount >= first.seconds { pending.removeFirst() } else { pending[0].seconds -= amount }
        }
        // Defensive memory bound; gaps and inconsistent signals must not grow a log.
        if pending.count > 1200 { pending.removeAll() }
    }
    mutating func beginManual() { manualStarted = document.enabled; pending.removeAll(); eligibleNatural = false; naturalKinds.removeAll(); naturalSeconds = 0 }
    mutating func cancelManual() { manualStarted = false }
    mutating func completeManual(day: String, duration: Double, eyes: Double, movement: Double) {
        guard document.enabled, manualStarted, duration.isFinite else { return }; manualStarted = false
        let eye = duration >= eyes, move = duration >= movement
        guard eye || move else { return }
        let capped = min(duration, max(eye ? eyes : 0, move ? movement : 0))
        edit(day) { row in
            row.breaks = min(8640, row.breaks + 1)
            if eye { row.eyes = min(row.breaks, row.eyes + 1) }; if move { row.movement = min(row.breaks, row.movement + 1) }
            row.rest = min(86_400, row.rest + capped)
        }
    }
    mutating func natural(day: String, kind: MolaKind, target: Double) {
        guard document.enabled, eligibleNatural, !naturalKinds.contains(kind), target.isFinite, target > 0 else { return }
        let first = naturalKinds.isEmpty; naturalKinds.insert(kind)
        if first { naturalDay = day }
        let addition = max(0, target - naturalSeconds); naturalSeconds = max(target, naturalSeconds)
        edit(naturalDay ?? day) { row in
            // A continuous absence is one break even if it satisfies both timers.
            if first { row.breaks = min(8640, row.breaks + 1); row.natural = min(row.breaks, row.natural + 1) }
            if kind == .eyes { row.eyes = min(row.breaks, row.eyes + 1) } else { row.movement = min(row.breaks, row.movement + 1) }
            row.rest = min(86_400, row.rest + addition)
        }
    }
}

struct StatisticsComparison {
    let currentAverage: Double
    let previousAverage: Double
    let currentDays: Int
    let previousDays: Int
    var percent: Int { Int(((currentAverage / previousAverage) - 1) * 100) }
    static func make(days: [DailySummary], period: Int, today: String) -> Self? {
        guard [7, 30].contains(period) else { return nil }
        let end = StatsCalendar.shifted(today, days: -period)
        let currentKeys = Set(StatsCalendar.recent(period, today: today, includeToday: false))
        let previousKeys = Set(StatsCalendar.recent(period, today: end, includeToday: false))
        let a = days.filter { currentKeys.contains($0.day) && $0.observed >= 60 }
        let b = days.filter { previousKeys.contains($0.day) && $0.observed >= 60 }
        let minDays = Int(ceil(Double(period) * 0.7))
        guard a.count >= minDays, b.count >= minDays else { return nil }
        let av = a.reduce(0) { $0 + $1.active } / Double(a.count), bv = b.reduce(0) { $0 + $1.active } / Double(b.count)
        guard av >= 60, bv >= 60 else { return nil }
        return Self(currentAverage: av, previousAverage: bv, currentDays: a.count, previousDays: b.count)
    }
}
