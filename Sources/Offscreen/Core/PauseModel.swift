import Foundation

enum PauseOption: CaseIterable {
    case thirtyMinutes, oneHour, tomorrow, untilResumed

    var title: String {
        switch self {
        case .thirtyMinutes: L("Pause for 30 minutes")
        case .oneHour: L("Pause for 1 hour")
        case .tomorrow: L("Pause until tomorrow")
        case .untilResumed: L("Pause until I resume")
        }
    }
}

enum ManualPause: Codable, Equatable {
    case until(Date)
    case nextLocalNine(started: Date)
    case untilResumed
}

enum PauseReason: Hashable {
    case manual, officeHours, sleepOrLock, automaticActivity
}

/// One source of truth for independent pause reasons. Only the user's manual
/// choice is saved; transient activity and system signals are sampled anew.
struct PauseModel {
    private(set) var manual: ManualPause?
    private(set) var officeHours = false
    private(set) var sleepOrLock = false
    private(set) var automaticActivity = false
    private let fileURL: URL

    init(fileURL: URL, now: Date = Date()) {
        self.fileURL = fileURL
        if let data = Self.read(fileURL),
           let saved = try? JSONDecoder().decode(ManualPause.self, from: data) {
            manual = saved
        }
        expire(now: now)
    }

    private static func read(_ url: URL) -> Data? {
        let descriptor = open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard descriptor >= 0 else { return nil }
        let file = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        defer { try? file.close() }
        var metadata = stat()
        guard fstat(descriptor, &metadata) == 0, metadata.st_mode & S_IFMT == S_IFREG,
              (0...256).contains(metadata.st_size) else { return nil }
        return try? file.read(upToCount: 257)
    }

    var reasons: Set<PauseReason> {
        var result: Set<PauseReason> = []
        if manual != nil { result.insert(.manual) }
        if officeHours { result.insert(.officeHours) }
        if sleepOrLock { result.insert(.sleepOrLock) }
        if automaticActivity { result.insert(.automaticActivity) }
        return result
    }
    var isPaused: Bool { !reasons.isEmpty }
    var isManuallyPaused: Bool { manual != nil }
    func deadline(calendar: Calendar = .autoupdatingCurrent) -> Date? {
        switch manual {
        case .until(let date): date
        case .nextLocalNine(let started):
            calendar.nextDate(after: started, matching: DateComponents(hour: 9, minute: 0, second: 0),
                              matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward)
        case .untilResumed, nil: nil
        }
    }

    mutating func select(_ option: PauseOption, now: Date = Date()) {
        switch option {
        case .thirtyMinutes: manual = .until(now.addingTimeInterval(1800))
        case .oneHour: manual = .until(now.addingTimeInterval(3600))
        case .tomorrow:
            // M4 can supply the next Office Hours start here. Until then this
            // follows the next local 09:00 if the system time zone changes.
            manual = .nextLocalNine(started: now)
        case .untilResumed: manual = .untilResumed
        }
        save()
    }

    mutating func resumeManually() { manual = nil; save() }
    mutating func setOfficeHours(_ active: Bool) { officeHours = active }
    mutating func setSleepOrLock(_ active: Bool) { sleepOrLock = active }
    mutating func setAutomaticActivity(_ active: Bool) { automaticActivity = active }

    mutating func expire(now: Date, calendar: Calendar = .autoupdatingCurrent) {
        if let deadline = deadline(calendar: calendar), now >= deadline { resumeManually() }
    }

    private func save() {
        if let manual, let data = try? JSONEncoder().encode(manual) {
            do {
                try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: fileURL, options: .atomic)
                try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
            } catch { Log.app.error("Manual pause could not be saved.") }
        } else {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}
