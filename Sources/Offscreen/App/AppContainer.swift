import AppKit
import Observation

// MIT derivative of Offscreen's scheduler, with independent activity and reminder policies.
enum MolaKind: String, CaseIterable, Identifiable, Sendable {
    case short, long
    var id: String { rawValue }
    var title: String { L(self == .short ? "Short break" : "Long break") }
    var shortTitle: String { L(self == .short ? "Short" : "Long") }
    var symbol: String { self == .short ? "eye" : "figure.walk" }
    var message: String { L(self == .short ? "Look away from the screen. Let your eyes rest." : "Stand up and take a short walk. Relax your shoulders.") }
}

@Observable final class AppContainer {
    let settings: SettingsStore
    let login = LoginItemManager()
    let sound = SoundPlayer()
    let statistics: StatisticsStore
    let breakEngine: BreakEngine
    private(set) var activity: ActivityState = .starting
    private(set) var videoAvailable = true
    private(set) var videoPlaying = false
    private(set) var cameraActive: Bool?
    private(set) var focusActive: Bool?
    private(set) var m8Signals = QuietSignalSnapshot()
    var audioInputActive: Bool? { m8Signals.audioInputActive }
    var fullScreenActive: Bool? { m8Signals.fullScreenActive }
    var selectedAppActive: Bool? { m8Signals.selectedAppActive }
    private let quietSignalReader: (AppSettings) -> QuietSignalSnapshot
    private(set) var idleSeconds: Double = 0
    private(set) var activeRest: MolaKind?
    private(set) var pause: PauseModel
    private(set) var watchingUntil: Date?
    private(set) var presentationUntil: Date?
    var settingsTab = 0
    private var restReturn = RestReturnPolicy()
    var loginError: String?
    var feedback: String?
    var loginEnabled = false
    var reminderKinds: Set<MolaKind> = []
    var isPreview = false
    var openSettingsAction: (() -> Void)?
    var openDashboardAction: (() -> Void)?
    var updateUI: (() -> Void)?
    var showReminder: (() -> Void)?
    var hideReminder: (() -> Void)?
    var refreshReminder: (() -> Void)?
    var notifications: LocalNotificationService?
    private let wallClock: () -> Date
    private let localCalendar: () -> Calendar
    private var timer: Timer?
    private var sleepMonitor: SleepWakeMonitor?
    private var suspended: Bool { pause.reasons.contains(.sleepOrLock) }
    private let origin = ContinuousClock.now
    private var previousTime: Double?
    private var nextSensorRead = 0.0
    private var restStarted: Double = 0
    private var reminderShownAt: Double?
    private(set) var skipCountdown: Int?
    private var accounting = ActivityAccounting()
    private var policy = ReminderPolicy()
    private var typingDeferral = TypingDeferral()
    private(set) var typingDeferralRemaining: Double?
    private(set) var keyboardTimingAvailable = false
    var typingDeferred: Bool { typingDeferralRemaining != nil }
    private var credited = false
    private var pendingDue: Set<MolaKind> = []
    private var activityToken: NSObjectProtocol?

    init(settings: SettingsStore = SettingsStore(), statistics: StatisticsStore = StatisticsStore(),
         wallClock: @escaping () -> Date = { Date() }, localCalendar: @escaping () -> Calendar = { .autoupdatingCurrent },
         quietSignalReader: @escaping (AppSettings) -> QuietSignalSnapshot = { QuietSignalMonitor.read(config: $0) }) {
        self.quietSignalReader = quietSignalReader
        self.wallClock = wallClock
        self.localCalendar = localCalendar
        self.settings = settings
        self.statistics = statistics
        pause = PauseModel(fileURL: settings.pauseFileURL, now: wallClock(), officeHours: settings.settings.officeHours, calendar: localCalendar())
        breakEngine = BreakEngine(timing: settings.settings.timing)
        breakEngine.restoreCadence(settings.settings.cycleShortCount)
        Localization.shared.language = settings.settings.language
        applyAppearance()
        statistics.startScoreCycle(fromBeginning: true)
        breakEngine.gentleReminders = true
        breakEngine.addListener { [weak self] event in
            guard let self else { return }
            switch event {
            case .reminderDue: pendingDue.insert(nextKind); observeScoreOpportunity()
            case .breakEnded(_, .completed, let duration):
                if activeRest != nil { finishRest(duration: duration) }
            default: break
            }
        }
        settings.addListener { [weak self] value in
            guard let self else { return }
            if activeRest == nil {
                if breakEngine.timing != value.timing {
                    statistics.startScoreCycle(fromBeginning: breakEngine.workAccrued == 0)
                }
                breakEngine.timing = value.timing
            }
            updateSkipCountdown(at: time)
            breakEngine.restoreCadence(value.cycleShortCount)
            Localization.shared.language = value.language
            applyAppearance()
            nextSensorRead = 0
            refreshQuietSignals()
            if !value.typingDeferralEnabled { typingDeferralRemaining = nil }
            refreshSchedule()
            refreshReminder?()
            updateUI?()
        }
        loginEnabled = login.isEnabled
    }
    var config: AppSettings { settings.settings }
    func engine(_ kind: MolaKind) -> BreakEngine { breakEngine }
    var time: Double { origin.duration(to: .now).seconds }
    var nextKind: MolaKind { breakEngine.nextBreakKind == .long ? .long : .short }
    struct TimerReadout {
        let kind: MolaKind
        let seconds: Double
        let resting: Bool
        let deferred: Bool
        var clock: String { Format.clock(seconds) }
        var menuText: String { clock }
    }
    func readout(for kind: MolaKind) -> TimerReadout {
        let timer = engine(kind), resting = activeRest == kind
        return TimerReadout(kind: kind, seconds: resting ? timer.breakRemaining : (typingDeferralRemaining ?? timer.timeUntilReminder),
                            resting: resting, deferred: !resting && timer.timeUntilBreak <= 0 && timer.timeUntilReminder > 0)
    }
    var nextReadout: TimerReadout { readout(for: activeRest ?? nextKind) }
    var cursorCountdownSeconds: Int? {
        let eligible = !isPreview && reminderKinds.isEmpty && activeRest == nil &&
            !pause.isPaused && !suppressing && (activity == .active || activity == .video)
        return CursorCountdownPolicy.seconds(remaining: breakEngine.timeUntilBreak,
            enabled: config.showCursorCountdown, eligible: eligible)
    }
    var canSkipBreak: Bool {
        !isPreview && skipCountdown == 0 &&
        (activeRest != nil || (!reminderKinds.isEmpty && breakEngine.timeUntilBreak <= 0))
    }
    func updateSkipCountdown(at now: Double) {
        guard !isPreview, activeRest != nil || !reminderKinds.isEmpty else { skipCountdown = nil; return }
        switch config.skipMode {
        case .casual: skipCountdown = 0
        case .hardcore: skipCountdown = nil
        case .balanced:
            let start = activeRest == nil ? reminderShownAt : restStarted
            skipCountdown = start.map { max(0, Int(ceil(Double(breakEngine.behavior.skipEnableDelaySeconds) - max(0, now - $0)))) }
        }
    }
    func markReminderShown(at now: Double) {
        reminderShownAt = now
        updateSkipCountdown(at: now)
    }
    var ringProgress: RingProgress {
        RingProgress(workAccrued: breakEngine.workAccrued, workSeconds: breakEngine.timing.workSeconds,
                     restRemaining: activeRest == nil ? nil : breakEngine.breakRemaining,
                     restDuration: activeRest == nil ? nil : breakEngine.breakDuration,
                     completedShorts: breakEngine.shortBreaksSinceLong,
                     shortsBeforeLong: config.shortBreaksBeforeLong)
    }
    var isPaused: Bool { pause.isManuallyPaused }
    var pauseUntil: Date? { pause.deadline(calendar: localCalendar(), officeHours: config.officeHours) }
    var outsideOfficeHours: Bool { pause.reasons.contains(.officeHours) }
    var officeHoursText: String {
        guard config.officeHours.enabled else { return L("Office Hours off") }
        return L(outsideOfficeHours ? "Outside Office Hours · paused" : "Within Office Hours")
    }
    var nextOfficeStartText: String? {
        guard config.officeHours.enabled else { return nil }
        guard let next = config.officeHours.nextStart(after: wallClock(), calendar: localCalendar()) else {
            return L("No working days selected. Timers stay paused; manual breaks remain available.")
        }
        return L("Next work start") + ": " + pauseDateText(next)
    }
    private func pauseDateText(_ date: Date) -> String {
        let calendar = localCalendar()
        return date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened,
            locale: Locale(identifier: Localization.shared.code), calendar: calendar, timeZone: calendar.timeZone))
    }
    func openOfficeHours() { settingsTab = 1; openSettingsAction?() }
    var manualPauseText: String {
        if let until = pauseUntil { return L("Paused until") + " " + pauseDateText(until) }
        if case .nextLocalNine = pause.manual, config.officeHours.enabled {
            return L("Paused until a selected work start")
        }
        return L("Paused until you resume")
    }
    var isWatching: Bool { watchingUntil != nil }
    var smartPause: SmartPause {
        SmartPause(config: config, videoPlaying: videoPlaying, watching: isWatching,
                   cameraActive: cameraActive, focusActive: focusActive, presenting: presentationUntil != nil,
                   audioInputActive: audioInputActive, fullScreenActive: fullScreenActive, selectedAppActive: selectedAppActive)
    }
    var suppressionReasons: [String] { smartPause.quietReasons.map { L($0.rawValue) } }
    var suppressing: Bool { !suppressionReasons.isEmpty }
    private var reminderEligible: Bool { !pause.isPaused && !suppressing && [.active, .video, .resting].contains(activity) }
    var canPresent: Bool { reminderEligible && !typingDeferred }
    var hasAlertProblem: Bool { config.reminderStyle == .notification && notifications?.hasProblem == true }
    func openAlertSettings() { settingsTab = 2; openSettingsAction?() }
    func notificationDeliveryFailed() { pendingDue.formUnion(reminderKinds); updateUI?() }
    func overdueLevel(_ kind: MolaKind) -> OverdueLevel {
        OverdueLevel.evaluate(enabled: config.overdueEnabled, overdue: -engine(kind).timeUntilBreak,
            snoozes: engine(kind).explicitDeferrals, amberMinutes: config.amberMinutes, redMinutes: config.redMinutes)
    }
    var visibleOverdue: OverdueLevel {
        guard !suppressing, !pause.isPaused, activeRest == nil, [.active, .video].contains(activity) else { return .normal }
        return overdueLevel(nextKind)
    }
    func reminderMessage(_ kind: MolaKind) -> String {
        guard !isPreview, activeRest == nil else { return kind.message }
        guard overdueLevel(kind) != .normal else { return kind.message }
        let minutes = Int(max(0, -breakEngine.timeUntilBreak) / 60)
        return String(format: L("%@ has been waiting for %d minutes. Take a short break when you can."), kind.title, minutes)
    }
    func openStatistics() { settingsTab = 5; openSettingsAction?() }
    func setStatisticsEnabled(_ value: Bool) {
        statistics.setEnabled(value, now: wallClock())
        statistics.startScoreCycle(fromBeginning: breakEngine.workAccrued == 0 && activeRest == nil)
        if !value { notifications?.clearWeekly() }
    }
    func setWeeklySummary(_ value: Bool) {
        statistics.setWeekly(value)
        if value { notifications?.request() } else { notifications?.clearWeekly() }
    }
    func clearStatistics() { statistics.clear(); notifications?.clearWeekly() }
    var canPreview: Bool { !suspended && !suppressing }
    var statusText: String {
        if suspended { return L("Screen off · paused") }
        if activeRest != nil { return L("Enjoy your break") }
        if isPaused { return manualPauseText }
        if outsideOfficeHours { return officeHoursText }
        if suppressing { return L("Alerts quiet") + " · " + suppressionReasons.joined(separator: ", ") }
        if hasAlertProblem { return L("Notifications need attention") }
        if let until = watchingUntil { return L("Watching until") + " " + until.formatted(date: .omitted, time: .shortened) }
        if policy.releaseAt != nil { return L("Alerts resume shortly") }
        if typingDeferred { return L("Typing · reminder delayed briefly") }
        return activity.title
    }
    func applyAppearance() {
        NSApp?.appearance = config.appearance == .system ? nil : NSAppearance(named: config.appearance == .dark ? .darkAqua : .aqua)
    }
    func nextTickDelay(sampleAge: Double = 0) -> TimeInterval {
        let counting = !suspended && (activeRest != nil ||
            (!pause.isPaused && [.active, .video].contains(activity)))
        return CountdownCadence.delay(remaining: nextReadout.seconds, counting: counting, sampleAge: sampleAge)
    }

    private func scheduleNextTick(sampledAt now: Double) {
        guard let timer, timer.isValid else { return }
        timer.fireDate = Date().addingTimeInterval(nextTickDelay(sampleAge: max(0, time - now)))
    }

    func start() {
        sleepMonitor = SleepWakeMonitor(onSuspend: { [weak self] in
            guard let self else { return }
            suspendTracking()
        }, onResume: { [weak self] gap in
            guard let self else { return }
            resumeTracking(after: gap); tick()
        })
        timer = Poll.every(1) { [weak self] in self?.tick() }
        tick()
        play(config.startTone)
    }
    func suspendTracking() {
        pause.setSleepOrLock(true)
        typingDeferralRemaining = nil
        if activeRest != nil { cancelRest(restartCycle: false) }
        m8Signals = QuietSignalSnapshot()
        statistics.resetSession(); statistics.flush(); hideReminder?(); sound.stop(); releaseActivity()
    }
    func resumeTracking(after gap: Double) {
        refreshSchedule()
        pause.setSleepOrLock(false)
        applyNaturalRest(gap)
        accounting.resumeAfterSuspension()
        previousTime = nil; nextSensorRead = 0
    }
    func refreshQuietSignals() {
        guard !suspended else { m8Signals = QuietSignalSnapshot(); return }
        m8Signals = quietSignalReader(config)
    }
    private func readSensors(now: Double) {
        guard !suspended else { return }
        guard now >= nextSensorRead else { return }
        nextSensorRead = now + 5
        if config.videoEnabled && !isPaused && !pause.reasons.contains(.officeHours) && activeRest == nil {
            let reading = MediaMonitor.read()
            videoAvailable = reading.available; videoPlaying = reading.isPlaying
        } else { videoPlaying = false; if !config.videoEnabled { videoAvailable = true } }
        cameraActive = config.cameraSuppression ? CameraStateMonitor.read() : nil
        focusActive = config.focusSuppression ? FocusMonitor.read() : nil
        refreshQuietSignals()
    }
    private func refreshSchedule() {
        let wasPaused = isPaused, wasOutside = outsideOfficeHours
        let date = wallClock(), calendar = localCalendar()
        pause.setOfficeHours(!config.officeHours.isOpen(at: date, calendar: calendar))
        pause.expire(now: date, calendar: calendar, officeHours: config.officeHours)
        if wasPaused != isPaused || wasOutside != outsideOfficeHours { nextSensorRead = 0 }
        if outsideOfficeHours && activeRest == nil {
            activity = suspended ? .sleeping : .paused
            if !isPreview && (!wasOutside || !reminderKinds.isEmpty) { dismissReminder(); sound.stop() }
            releaseActivity()
        }
    }
    func tick() {
        refreshSchedule()
        let now = time
        readSensors(now: now)
        tick(now: now, idle: suspended ? idleSeconds : IdleMonitor.idleSeconds(),
             deliberateIdle: activeRest == nil ? .infinity : IdleMonitor.deliberateIdleSeconds(),
             keyboardIdle: config.typingDeferralEnabled && !suspended && activeRest == nil ? IdleMonitor.keyboardIdleSeconds() : nil)
    }
    // Sensor-independent entry point also used by deterministic lifecycle regression tests.
    func tick(now: Double, idle: Double, deliberateIdle: Double, keyboardIdle: Double? = nil) {
        defer { scheduleNextTick(sampledAt: now) }
        let previousState = activity
        let rawDelta = previousTime.map { now - $0 } ?? 0
        let delta = rawDelta >= 0 && rawDelta <= 5 ? rawDelta : 0
        previousTime = now
        refreshSchedule()
        let oldSkipCountdown = skipCountdown
        updateSkipCountdown(at: now)
        if oldSkipCountdown != 0 && skipCountdown == 0 && config.skipMode == .balanced &&
           config.reminderStyle == .notification && activeRest == nil && !reminderKinds.isEmpty && canPresent {
            showReminder?()
        }
        if let until = watchingUntil, wallClock() >= until { watchingUntil = nil }
        if let until = presentationUntil, wallClock() >= until { presentationUntil = nil }
        idleSeconds = idle
        let decision = accounting.step(now: now, idle: idleSeconds,
            video: activeRest == nil && smartPause.keepsCounting,
            locked: suspended, paused: isPaused || pause.reasons.contains(.officeHours), resting: activeRest != nil,
            threshold: Double(config.idlePauseSeconds))
        if !suspended { pause.setAutomaticActivity(decision.automaticPause) }
        activity = decision.state
        if suspended {
            if activeRest != nil { cancelRest(restartCycle: false) }
            activity = .sleeping
            applyNaturalRest(decision.restCredit)
            updateUI?(); return
        }
        if let kind = activeRest {
            if suppressing { hideReminder?(); sound.stop(); notifications?.clearWeekly() }
            _ = policy.update(now: now, suppressed: suppressing, eligible: false, due: [])
            // A return on the completion tick must finish, rather than cancel, the rest.
            if engine(kind).breakRemaining <= delta {
                engine(kind).advance(by: delta)
            } else if restReturn.shouldResume(now: now, restStarted: restStarted, idle: idleSeconds, deliberateIdle: deliberateIdle) {
                cancelRest(restartCycle: false)
            } else { activity = .resting; engine(kind).advance(by: delta) }
            updateUI?(); return
        }
        statistics.sample(now: wallClock(), uptime: now, active: decision.activeSeconds, rollback: decision.rollback,
            provisional: accounting.unconfirmedSeconds,
            observed: isPaused || pause.reasons.contains(.officeHours) || activity == .starting ? 0 : delta,
            video: config.videoEnabled && videoPlaying, watching: isWatching)
        breakEngine.removeProvisionalWork(decision.rollback)
        applyNaturalRest(decision.restCredit)
        if activity == .active || activity == .video {
            credited = false
            // Keeps the timers responsive without preventing display or system sleep.
            if timer != nil && activityToken == nil { activityToken = ProcessInfo.processInfo.beginActivity(options: .userInitiatedAllowingIdleSystemSleep, reason: "Local break timer") }
            breakEngine.advance(by: decision.activeSeconds)
        } else { releaseActivity(); if !isPreview { hideReminder?(); reminderKinds.removeAll() } }
        observeScoreOpportunity()
        keyboardTimingAvailable = keyboardIdle.map { $0.isFinite && $0 >= 0 } ?? false
        typingDeferralRemaining = typingDeferral.update(now: now, cycleDue: breakEngine.timeUntilBreak <= 0,
            pending: !pendingDue.isEmpty || !policy.pending.isEmpty,
            eligible: reminderEligible && !hasAlertProblem && !isPreview && !policy.held && (policy.releaseAt.map { now >= $0 } ?? true),
            enabled: config.typingDeferralEnabled, keyboardIdle: keyboardIdle)
        let ready = policy.update(now: now, suppressed: suppressing, eligible: canPresent && !hasAlertProblem && !isPreview, due: pendingDue)
        pendingDue.removeAll()
        if suppressing { hideReminder?(); sound.stop(); notifications?.clearWeekly() }
        if !ready.isEmpty {
            reminderKinds = ready
            breakEngine.deferReminder()
            isPreview = false
            markReminderShown(at: now)
            showReminder?()
            if config.reminderStyle != .notification { play(config.reminderTone) }
        }
        if canPresent && activeRest == nil && reminderKinds.isEmpty && policy.releaseAt == nil,
           statistics.reportDue(), notifications?.authorization == .authorized, notifications?.alertsEnabled == true {
            notifications?.showWeekly()
        }
        if previousState != activity {
            if [.away, .paused].contains(activity) { play(config.pauseTone, transition: true) }
            else if [.away, .paused, .starting].contains(previousState) && [.active, .video].contains(activity) { play(config.resumeTone, transition: true) }
        }
        updateUI?()
    }
    private func observeScoreOpportunity() {
        statistics.observeScoreOpportunity(confirmedDue:
            breakEngine.workAccrued - accounting.unconfirmedSeconds >= Double(breakEngine.timing.workSeconds))
    }
    private func applyNaturalRest(_ duration: Double) {
        guard !credited else { return }
        var duration = duration
        if config.officeHours.enabled {
            let now = wallClock()
            guard let interval = config.officeHours.interval(containing: now, calendar: localCalendar()) else { return }
            // Off-hours absence never completes a break or advances cadence.
            duration = min(duration, max(0, now.timeIntervalSince(interval.start)))
        }
        let kind = nextKind
        let target = Double(BreakScheduleMath.duration(of: breakEngine.nextBreakKind, timing: breakEngine.timing))
        guard duration >= target else { return }
        observeScoreOpportunity()
        statistics.resolveScoreOpportunity(completed: true, now: wallClock())
        if !suspended { statistics.naturalCycle(kind: kind, target: target, now: wallClock()) }
        breakEngine.accountForNaturalRest(duration)
        settings.update { $0.cycleShortCount = breakEngine.shortBreaksSinceLong }; settings.flush()
        typingDeferral.reset(); typingDeferralRemaining = nil
        policy.clear(kind); pendingDue.removeAll(); reminderKinds.removeAll(); credited = true
    }
    func beginRest(_ kind: MolaKind, now: Double? = nil) {
        guard !suspended else { return }
        if activeRest != nil { cancelRest() }
        observeScoreOpportunity()
        statistics.beginManual()
        let selected = kind == .long ? MolaKind.long : nextKind
        activeRest = selected; restStarted = now ?? time; restReturn.reset()
        typingDeferralRemaining = nil
        reminderShownAt = nil
        accounting.clearProvisional(); reminderKinds = [selected]; isPreview = false
        updateSkipCountdown(at: restStarted)
        policy.clear(selected)
        if selected == .long { breakEngine.startLongBreakNow() } else { breakEngine.startBreakNow() }
        activity = .resting
        showReminder?(); play(config.breakTone); updateUI?()
        scheduleNextTick(sampledAt: restStarted)
    }
    func cancelRest(restartCycle: Bool = false) {
        guard let kind = activeRest else { return }
        statistics.cancelManual()
        if restartCycle {
            statistics.startScoreCycle(fromBeginning: true)
            breakEngine.restartWorkCycle()
        }
        else { breakEngine.cancelBreakKeepingProgress() }
        policy.clear(kind); pendingDue.remove(kind)
        activeRest = nil
        skipCountdown = nil
        breakEngine.timing = config.timing
        dismissReminder(); accounting.clearProvisional(); activity = pause.isPaused ? .paused : .active; nextSensorRead = 0
        play(config.resumeTone, transition: true); updateUI?()
    }
    private func finishRest(duration: Double) {
        guard let kind = activeRest else { return }
        statistics.resolveScoreOpportunity(completed: true, now: wallClock())
        statistics.completeCycle(kind: kind, duration: duration, now: wallClock())
        typingDeferral.reset(); typingDeferralRemaining = nil
        settings.update { $0.cycleShortCount = breakEngine.shortBreaksSinceLong }; settings.flush()
        policy.clear(kind); pendingDue.remove(kind)
        activeRest = nil; breakEngine.timing = config.timing
        skipCountdown = nil
        dismissReminder(); accounting.clearProvisional(); activity = .active
        nextSensorRead = 0; play(config.endTone)
    }
    func dismissReminder() {
        reminderKinds.removeAll(); reminderShownAt = nil; skipCountdown = nil
        isPreview = false; updateSkipCountdown(at: time); hideReminder?()
    }
    @discardableResult func skipBreak(now: Double? = nil) -> Bool {
        updateSkipCountdown(at: now ?? time)
        guard canSkipBreak else { return false }
        if activeRest == nil { observeScoreOpportunity() }
        statistics.resolveScoreOpportunity(completed: false, now: wallClock())
        if activeRest != nil { statistics.cancelManual() }
        let kind = activeRest ?? nextKind
        breakEngine.skipBreak()
        typingDeferral.reset(); typingDeferralRemaining = nil
        policy.clear(kind); pendingDue.remove(kind)
        activeRest = nil; breakEngine.timing = config.timing
        dismissReminder(); accounting.clearProvisional(); activity = pause.isPaused ? .paused : .active; nextSensorRead = 0
        play(config.resumeTone, transition: true); updateUI?()
        return true
    }
    func snoozeReminder() {
        if !isPreview && !reminderKinds.isEmpty {
            // Snooze is a quiet period for all break alerts. Preserve any later
            // deadline and count a deliberate deferral only for the shown kinds.
            breakEngine.deferReminder(seconds: max(300, breakEngine.timeUntilReminder), explicit: true)
            policy.clear(nextKind)
            pendingDue.removeAll()
        }
        dismissReminder(); updateUI?()
    }
    func previewReminder() {
        guard canPreview else { feedback = L("End quiet mode before previewing."); return }
        isPreview = true; reminderKinds = [nextKind]; showReminder?()
        if config.reminderStyle != .notification { play(config.reminderTone) }
    }
    func pauseTracking(_ option: PauseOption) {
        statistics.resetSession()
        if activeRest != nil { cancelRest() }
        pause.select(option, now: wallClock())
        typingDeferralRemaining = nil
        dismissReminder()
        tick()
    }
    func resumeManualPause() {
        pause.resumeManually()
        nextSensorRead = 0
        tick()
    }
    func toggleWatching() { watchingUntil = isWatching ? nil : Date().addingTimeInterval(Double(config.watchingMinutes * 60)); tick() }
    func extendWatching() { watchingUntil = (watchingUntil ?? Date()).addingTimeInterval(Double(config.watchingMinutes * 60)); tick() }
    func togglePresentation() { presentationUntil = presentationUntil == nil ? Date().addingTimeInterval(Double(config.presentationMinutes * 60)) : nil; tick() }
    func requestFocus() { FocusMonitor.request { [weak self] in self?.nextSensorRead = 0; self?.tick() } }
    func play(_ choice: SoundChoice, transition: Bool = false) {
        guard !suspended, !suppressing else { return }
        sound.play(choice, volume: config.soundVolume, now: time, transition: transition)
    }
    func setLogin(_ enabled: Bool) {
        loginError = login.setEnabled(enabled).map { _ in L("Could not change login item. Check System Settings.") }
        loginEnabled = login.isEnabled
    }
    private func releaseActivity() { if let token = activityToken { ProcessInfo.processInfo.endActivity(token); activityToken = nil } }
    func stop() { timer?.invalidate(); sleepMonitor?.stop(); releaseActivity(); sound.stop(); notifications?.clear(); statistics.flush(); settings.flush() }
}
