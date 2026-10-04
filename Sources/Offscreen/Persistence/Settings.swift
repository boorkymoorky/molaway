import Foundation
import Darwin

/// Timing for the recurring work → break cycle. All values are "virtual"
/// seconds — the engine scales real elapsed time by OFFSCREEN_TIME_SCALE.
struct TimingConfig: Codable, Equatable, Sendable {
    var workSeconds: Int = 20 * 60
    var shortBreakSeconds: Int = 20
    var longBreakEvery: Int = 4 // engine rule: after 3 completed shorts; 0 = never
    var longBreakSeconds: Int = 5 * 60
    var leadTimeSeconds: Int = 60 // heads-up notice before a break
    var snoozeLimitPerCycle: Int = 3

    static let balanced = TimingConfig()
    static let deepFocus = TimingConfig(
        workSeconds: 45 * 60,
        shortBreakSeconds: 30,
        longBreakEvery: 2,
        longBreakSeconds: 8 * 60
    )
    static let twentyTwentyTwenty = TimingConfig(
        workSeconds: 20 * 60,
        shortBreakSeconds: 20,
        longBreakEvery: 0
    )

    static let presets: [(name: String, config: TimingConfig)] = [
        ("Balanced", .balanced),
        ("Deep Focus", .deepFocus),
        ("20-20-20", .twentyTwentyTwenty),
    ]

    var presetName: String {
        Self.presets.first { $0.config == self }?.name ?? "Custom"
    }
}

/// Break-experience behavior separate from timing.
struct BehaviorConfig: Codable, Equatable, Sendable {
    var skipEnableDelaySeconds: Int = 5 // Balanced mode: skip unlocks after this
    var endEarlyMinimumSeconds: Int? // nil = no "End Break" button
    var cursorPillSeconds: Int = 10 // countdown pill in the last N seconds
    var autoLockOnBreakStart: Bool = false
}

/// How hard it is to get out of a break.
enum DifficultyMode: String, Codable, CaseIterable, Sendable {
    case casual // skip any time
    case balanced // skip button enables after a delay
    case hardcore // no skipping

    var label: String {
        switch self {
        case .casual: L("Casual")
        case .balanced: L("Balanced")
        case .hardcore: L("Hardcore")
        }
    }
}


enum ReminderStyle: String, Codable, CaseIterable { case notification, corner, banner, fullScreen
    var title: String { L([.notification: "macOS notification", .corner: "Small card", .banner: "Top panel", .fullScreen: "Full screen"][self]!) }
}
enum AlertSurface: String, Codable, CaseIterable { case system, glass, solid
    var title: String { L(rawValue == "solid" ? "Solid" : rawValue.capitalized) }
}
enum DisplayTarget: String, Codable, CaseIterable { case cursor, primary, all
    var title: String { L([.cursor: "Cursor display", .primary: "Primary display", .all: "All displays"][self]!) }
}
enum AppLanguage: String, Codable, CaseIterable { case system, tr, en
    var title: String { self == .system ? L("System") : self == .tr ? "Türkçe" : "English" }
}
enum AppAppearance: String, Codable, CaseIterable { case system, light, dark
    var title: String { L(rawValue.capitalized) }
}
enum Accent: String, Codable, CaseIterable { case mint, blue, violet, rose
    var title: String { L(rawValue.capitalized) }
}
enum SoundChoice: String, Codable, CaseIterable { case none, soft, rise, fall, bell, tink = "Tink", pop = "Pop", glass = "Glass", purr = "Purr"
    var title: String { L(rawValue.capitalized) }
    var generated: Bool { [.soft, .rise, .fall, .bell].contains(self) }
}

struct AppSettings: Codable, Equatable, Sendable {
    var skipMode: DifficultyMode = .balanced
    var officeHours = OfficeHours()
    var schemaVersion: Int = 3
    var workMinutes: Int = 20
    var shortRestSeconds: Int = 20
    var longRestMinutes: Int = 2
    var shortBreaksBeforeLong: Int = 2 // 0 disables long breaks
    var cycleShortCount: Int = 0
    var migrationNoticePending: Bool = false
    var previousCustomTiming: TimingConfig?
    var eyeMinutes: Int = 20
    var movementMinutes: Int = 50
    var eyeRestSeconds: Int = 20
    var movementRestMinutes: Int = 2
    var idlePauseSeconds: Int = 120
    var showCountdownInMenuBar: Bool = true
    var showCursorCountdown: Bool = false
    var videoEnabled: Bool = true
    var typingDeferralEnabled: Bool = false
    var reminderVisibleSeconds: Int = 12
    var didFinishWelcome: Bool = false
    var reminderStyle: ReminderStyle = .banner
    var displayTarget: DisplayTarget = .cursor
    var language: AppLanguage = .system
    var appearance: AppAppearance = .system
    var accent: Accent = .mint
    var watchingMinutes: Int = 60
    var presentationMinutes: Int = 60
    var mergeBreaks: Bool = true
    var cameraSuppression: Bool = false
    var focusSuppression: Bool = false
    var reminderTone: SoundChoice = .none
    var startTone: SoundChoice = .none
    var pauseTone: SoundChoice = .none
    var resumeTone: SoundChoice = .none
    var breakTone: SoundChoice = .none
    var endTone: SoundChoice = .none
    var soundVolume: Double = 0.35
    var alertSurface: AlertSurface = .system
    var surfaceDensity: Double = 0.65
    var fullScreenDim: Double = 0.85
    var overdueEnabled = true
    var amberMinutes = 10
    var redMinutes = 20
    init() {}
    enum CodingKeys: String, CodingKey, CaseIterable {
        case typingDeferralEnabled, skipMode, officeHours, schemaVersion, workMinutes, shortRestSeconds, longRestMinutes, shortBreaksBeforeLong, cycleShortCount, migrationNoticePending, previousCustomTiming, eyeMinutes, movementMinutes, eyeRestSeconds, movementRestMinutes, idlePauseSeconds, showCountdownInMenuBar, showCursorCountdown, videoEnabled, reminderVisibleSeconds, didFinishWelcome, reminderStyle, displayTarget, language, appearance, accent, watchingMinutes, presentationMinutes, mergeBreaks, cameraSuppression, focusSuppression, reminderTone, startTone, pauseTone, resumeTone, breakTone, endTone, soundVolume, alertSurface, surfaceDensity, fullScreenDim, overdueEnabled, amberMinutes, redMinutes
    }
    private enum LegacyKeys: String, CodingKey { case chromeVideoEnabled, reminderSound }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let legacy = try decoder.container(keyedBy: LegacyKeys.self)
        let version = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        guard (1...3).contains(version) else { throw SettingsError.version }
        skipMode = try c.decodeIfPresent(DifficultyMode.self, forKey: .skipMode) ?? .balanced
        officeHours = try c.decodeIfPresent(OfficeHours.self, forKey: .officeHours) ?? OfficeHours()
        eyeMinutes = try c.decodeIfPresent(Int.self, forKey: .eyeMinutes) ?? 20
        movementMinutes = try c.decodeIfPresent(Int.self, forKey: .movementMinutes) ?? 50
        eyeRestSeconds = try c.decodeIfPresent(Int.self, forKey: .eyeRestSeconds) ?? 20
        movementRestMinutes = try c.decodeIfPresent(Int.self, forKey: .movementRestMinutes) ?? 2
        if version >= 3 {
            workMinutes = try c.decode(Int.self, forKey: .workMinutes)
            shortRestSeconds = try c.decode(Int.self, forKey: .shortRestSeconds)
            longRestMinutes = try c.decode(Int.self, forKey: .longRestMinutes)
            shortBreaksBeforeLong = try c.decode(Int.self, forKey: .shortBreaksBeforeLong)
            cycleShortCount = try c.decodeIfPresent(Int.self, forKey: .cycleShortCount) ?? 0
            migrationNoticePending = try c.decodeIfPresent(Bool.self, forKey: .migrationNoticePending) ?? false
            previousCustomTiming = try c.decodeIfPresent(TimingConfig.self, forKey: .previousCustomTiming)
        } else {
            workMinutes = eyeMinutes
            shortRestSeconds = eyeRestSeconds
            longRestMinutes = movementRestMinutes
            // Aim for a long break near the old movement interval. The old
            // independent movement timer cannot be reproduced exactly.
            let intervals = max(2, min(13, Int((Double(min(180, max(10, movementMinutes))) / Double(min(120, max(5, eyeMinutes)))).rounded())))
            shortBreaksBeforeLong = min(12, intervals - 1)
            cycleShortCount = 0
            migrationNoticePending = true
            previousCustomTiming = nil
        }
        idlePauseSeconds = try c.decodeIfPresent(Int.self, forKey: .idlePauseSeconds) ?? 120
        showCountdownInMenuBar = try c.decodeIfPresent(Bool.self, forKey: .showCountdownInMenuBar) ?? true
        showCursorCountdown = try c.decodeIfPresent(Bool.self, forKey: .showCursorCountdown) ?? false
        videoEnabled = try c.decodeIfPresent(Bool.self, forKey: .videoEnabled) ?? legacy.decodeIfPresent(Bool.self, forKey: .chromeVideoEnabled) ?? true
        typingDeferralEnabled = try c.decodeIfPresent(Bool.self, forKey: .typingDeferralEnabled) ?? false
        reminderVisibleSeconds = try c.decodeIfPresent(Int.self, forKey: .reminderVisibleSeconds) ?? 12
        didFinishWelcome = try c.decodeIfPresent(Bool.self, forKey: .didFinishWelcome) ?? false
        reminderStyle = try c.decodeIfPresent(ReminderStyle.self, forKey: .reminderStyle) ?? (version == 1 ? .corner : .banner)
        displayTarget = try c.decodeIfPresent(DisplayTarget.self, forKey: .displayTarget) ?? .cursor
        language = try c.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system
        appearance = try c.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system
        accent = try c.decodeIfPresent(Accent.self, forKey: .accent) ?? .mint
        watchingMinutes = try c.decodeIfPresent(Int.self, forKey: .watchingMinutes) ?? 60
        presentationMinutes = try c.decodeIfPresent(Int.self, forKey: .presentationMinutes) ?? 60
        mergeBreaks = try c.decodeIfPresent(Bool.self, forKey: .mergeBreaks) ?? true
        cameraSuppression = try c.decodeIfPresent(Bool.self, forKey: .cameraSuppression) ?? false
        focusSuppression = try c.decodeIfPresent(Bool.self, forKey: .focusSuppression) ?? false
        reminderTone = try c.decodeIfPresent(SoundChoice.self, forKey: .reminderTone) ?? (legacy.decodeIfPresent(Bool.self, forKey: .reminderSound) == true ? .tink : .none)
        startTone = try c.decodeIfPresent(SoundChoice.self, forKey: .startTone) ?? .none
        pauseTone = try c.decodeIfPresent(SoundChoice.self, forKey: .pauseTone) ?? .none
        resumeTone = try c.decodeIfPresent(SoundChoice.self, forKey: .resumeTone) ?? .none
        breakTone = try c.decodeIfPresent(SoundChoice.self, forKey: .breakTone) ?? .none
        endTone = try c.decodeIfPresent(SoundChoice.self, forKey: .endTone) ?? .none
        soundVolume = try c.decodeIfPresent(Double.self, forKey: .soundVolume) ?? 0.35
        alertSurface = try c.decodeIfPresent(AlertSurface.self, forKey: .alertSurface) ?? .system
        surfaceDensity = try c.decodeIfPresent(Double.self, forKey: .surfaceDensity) ?? 0.65
        fullScreenDim = try c.decodeIfPresent(Double.self, forKey: .fullScreenDim) ?? 0.85
        overdueEnabled = try c.decodeIfPresent(Bool.self, forKey: .overdueEnabled) ?? true
        amberMinutes = try c.decodeIfPresent(Int.self, forKey: .amberMinutes) ?? 10
        redMinutes = try c.decodeIfPresent(Int.self, forKey: .redMinutes) ?? 20
        schemaVersion = 3
        validate()
    }
    var timing: TimingConfig { TimingConfig(workSeconds: min(180, max(5, workMinutes)) * 60, shortBreakSeconds: min(120, max(10, shortRestSeconds)), longBreakEvery: shortBreaksBeforeLong <= 0 ? 0 : min(12, shortBreaksBeforeLong) + 1, longBreakSeconds: min(15, max(1, longRestMinutes)) * 60, leadTimeSeconds: 0) }
    mutating func applyPreset(_ preset: TimingConfig) {
        if previousCustomTiming == nil { previousCustomTiming = timing }
        workMinutes = preset.workSeconds / 60
        shortRestSeconds = preset.shortBreakSeconds
        longRestMinutes = preset.longBreakSeconds / 60
        shortBreaksBeforeLong = preset.longBreakEvery == 0 ? 0 : preset.longBreakEvery - 1
        cycleShortCount = 0
    }
    mutating func restorePreviousTiming() {
        guard let previousCustomTiming else { return }
        workMinutes = previousCustomTiming.workSeconds / 60
        shortRestSeconds = previousCustomTiming.shortBreakSeconds
        longRestMinutes = previousCustomTiming.longBreakSeconds / 60
        shortBreaksBeforeLong = previousCustomTiming.longBreakEvery == 0 ? 0 : previousCustomTiming.longBreakEvery - 1
        self.previousCustomTiming = nil
        cycleShortCount = 0
    }
    var eyes: TimingConfig { TimingConfig(workSeconds: min(120, max(5, eyeMinutes)) * 60, shortBreakSeconds: min(120, max(10, eyeRestSeconds)), longBreakEvery: 0, leadTimeSeconds: 0) }
    var movement: TimingConfig { TimingConfig(workSeconds: min(180, max(10, movementMinutes)) * 60, shortBreakSeconds: min(15, max(1, movementRestMinutes)) * 60, longBreakEvery: 0, leadTimeSeconds: 0) }
    mutating func validate() {
        officeHours.validate()
        schemaVersion = 3
        workMinutes = min(180, max(5, workMinutes))
        shortRestSeconds = min(120, max(10, shortRestSeconds))
        longRestMinutes = min(15, max(1, longRestMinutes))
        shortBreaksBeforeLong = min(12, max(0, shortBreaksBeforeLong))
        cycleShortCount = min(shortBreaksBeforeLong, max(0, cycleShortCount))
        amberMinutes = min(60, max(5, amberMinutes))
        redMinutes = min(120, max(amberMinutes + 5, redMinutes))
        eyeMinutes = min(120, max(5, eyeMinutes))
        movementMinutes = min(180, max(10, movementMinutes))
        eyeRestSeconds = min(120, max(10, eyeRestSeconds))
        movementRestMinutes = min(15, max(1, movementRestMinutes))
        idlePauseSeconds = min(600, max(30, idlePauseSeconds))
        reminderVisibleSeconds = min(30, max(5, reminderVisibleSeconds))
        watchingMinutes = min(240, max(5, watchingMinutes))
        presentationMinutes = min(240, max(5, presentationMinutes))
        surfaceDensity = surfaceDensity.isFinite ? min(1, max(0.3, surfaceDensity)) : 0.65
        fullScreenDim = fullScreenDim.isFinite ? min(1, max(0.4, fullScreenDim)) : 0.85
        soundVolume = soundVolume.isFinite ? min(1, max(0, soundVolume)) : 0.35
    }
}

enum SettingsError: Error { case version, size, fields, file }
enum SettingsCodec {
    static let maximumBytes = 65_536
    static func decode(_ data: Data, strict: Bool = false) throws -> AppSettings {
        guard data.count <= maximumBytes else { throw SettingsError.size }
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw SettingsError.fields }
        if strict {
            let allowed = Set(AppSettings.CodingKeys.allCases.map(\.rawValue) + ["chromeVideoEnabled", "reminderSound"])
            guard Set(object.keys).isSubset(of: allowed) else { throw SettingsError.fields }
        }
        return try JSONDecoder().decode(AppSettings.self, from: data)
    }
    static func read(_ url: URL, strict: Bool = false) throws -> AppSettings {
        let descriptor = open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard descriptor >= 0 else { throw SettingsError.file }
        let file = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        defer { try? file.close() }
        var metadata = stat()
        guard fstat(descriptor, &metadata) == 0, metadata.st_mode & S_IFMT == S_IFREG else { throw SettingsError.file }
        guard metadata.st_size >= 0, metadata.st_size <= maximumBytes else { throw SettingsError.size }
        let data = try file.read(upToCount: maximumBytes + 1) ?? Data()
        return try decode(data, strict: strict)
    }
    static func export(_ settings: AppSettings) throws -> Data {
        var safe = settings
        safe.didFinishWelcome = false
        safe.cycleShortCount = 0
        safe.migrationNoticePending = false
        safe.cameraSuppression = false
        safe.focusSuppression = false
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(safe)
    }
}
