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
    private var timer: Timer?
    private var sleepMonitor: SleepWakeMonitor?
    private var suspended: Bool { pause.reasons.contains(.sleepOrLock) }
    private let origin = ContinuousClock.now
    private var previousTime: Double?
    private var nextSensorRead = 0.0
    private var restStarted: Double = 0
    private var accounting = ActivityAccounting()
    private var policy = ReminderPolicy()
    private var credited = false
    private var pendingDue: Set<MolaKind> = []
    private var activityToken: NSObjectProtocol?

    init(settings: SettingsStore = SettingsStore(), statistics: StatisticsStore = StatisticsStore()) {
        self.settings = settings
        self.statistics = statistics
        pause = PauseModel(fileURL: settings.pauseFileURL)
        breakEngine = BreakEngine(timing: settings.settings.timing)
        breakEngine.restoreCadence(settings.settings.cycleShortCount)
        Localization.shared.language = settings.settings.language
        applyAppearance()
        breakEngine.gentleReminders = true
        breakEngine.addListener { [weak self] event in
            guard let self else { return }
            switch event {
            case .reminderDue: pendingDue.insert(nextKind)
            case .breakEnded(_, .completed, let duration):
                if activeRest != nil { finishRest(duration: duration) }
            default: break
            }
        }
        settings.addListener { [weak self] value in
            guard let self else { return }
            if activeRest == nil { breakEngine.timing = value.timing }
            breakEngine.restoreCadence(value.cycleShortCount)
            Localization.shared.language = value.language
            applyAppearance()
            nextSensorRead = 0
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
        var menuText: String { kind.shortTitle + " " + clock }
    }
    func readout(for kind: MolaKind) -> TimerReadout {
        let timer = engine(kind), resting = activeRest == kind
        return TimerReadout(kind: kind, seconds: resting ? timer.breakRemaining : timer.timeUntilReminder,
                            resting: resting, deferred: !resting && timer.timeUntilBreak <= 0 && timer.timeUntilReminder > 0)
    }
    var nextReadout: TimerReadout { readout(for: activeRest ?? nextKind) }
    var ringProgress: RingProgress {
        RingProgress(workAccrued: breakEngine.workAccrued, workSeconds: breakEngine.timing.workSeconds,
                     restRemaining: activeRest == nil ? nil : breakEngine.breakRemaining,
                     restDuration: activeRest == nil ? nil : breakEngine.breakDuration,
                     completedShorts: breakEngine.shortBreaksSinceLong,
                     shortsBeforeLong: config.shortBreaksBeforeLong)
    }
    var isPaused: Bool { pause.isManuallyPaused }
    var pauseUntil: Date? { pause.deadline() }
    var manualPauseText: String {
        if let until = pauseUntil { return L("Paused until") + " " + until.formatted(date: .abbreviated, time: .shortened) }
        return L("Paused until you resume")
    }
    var isWatching: Bool { watchingUntil != nil }
    var suppressionReasons: [String] {
        var reasons: [String] = []
        if presentationUntil != nil { reasons.append(L("Presentation mode")) }
        if config.cameraSuppression && cameraActive == true { reasons.append(L("Camera in use")) }
        if config.focusSuppression && focusActive == true { reasons.append(L("Focus")) }
        return reasons
    }
    var suppressing: Bool { !suppressionReasons.isEmpty }
    var canPresent: Bool { !pause.isPaused && !suppressing && activity != .away }
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
    func setStatisticsEnabled(_ value: Bool) { statistics.setEnabled(value); if !value { notifications?.clearWeekly() } }
    func setWeeklySummary(_ value: Bool) {
        statistics.setWeekly(value)
        if value { notifications?.request() } else { notifications?.clearWeekly() }
    }
    func clearStatistics() { statistics.clear(); notifications?.clearWeekly() }
    var canPreview: Bool { !suspended && !suppressing }
    var statusText: String {
        if suspended { return L("Screen off · paused") }
        if isPaused { return manualPauseText }
        if pause.reasons.contains(.officeHours) { return L("Outside Office Hours · paused") }
        if activeRest != nil { return L("Enjoy your break") }
        if suppressing { return L("Alerts quiet") + " · " + suppressionReasons.joined(separator: ", ") }
        if hasAlertProblem { return L("Notifications need attention") }
        if let until = watchingUntil { return L("Watching until") + " " + until.formatted(date: .omitted, time: .shortened) }
        if policy.releaseAt != nil { return L("Alerts resume shortly") }
        return activity.title
    }
    func applyAppearance() {
        NSApp?.appearance = config.appearance == .system ? nil : NSAppearance(named: config.appearance == .dark ? .darkAqua : .aqua)
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
        if activeRest != nil { cancelRest(restartCycle: false) }
        statistics.resetSession(); statistics.flush(); hideReminder?(); sound.stop(); releaseActivity()
    }
    func resumeTracking(after gap: Double) {
        pause.setSleepOrLock(false)
        applyNaturalRest(gap)
        accounting.resumeAfterSuspension()
        previousTime = nil; nextSensorRead = 0
    }
    private func readSensors(now: Double) {
        guard !suspended else { return }
        guard now >= nextSensorRead else { return }
        nextSensorRead = now + 5
        if config.videoEnabled && !isPaused && !pause.reasons.contains(.officeHours) && activeRest == nil {
            let reading = MediaMonitor.read()
            videoAvailable = reading.available; videoPlaying = reading.isPlaying
        } else if !config.videoEnabled { videoPlaying = false; videoAvailable = true }
        cameraActive = config.cameraSuppression ? CameraStateMonitor.read() : nil
        focusActive = config.focusSuppression ? FocusMonitor.read() : nil
    }
    func tick() {
        let now = time
        readSensors(now: now)
        tick(now: now, idle: suspended ? idleSeconds : IdleMonitor.idleSeconds(),
             deliberateIdle: activeRest == nil ? .infinity : IdleMonitor.deliberateIdleSeconds())
    }
    // Sensor-independent entry point also used by deterministic lifecycle regression tests.
    func tick(now: Double, idle: Double, deliberateIdle: Double) {
        let previousState = activity
        let rawDelta = previousTime.map { now - $0 } ?? 0
        let delta = rawDelta >= 0 && rawDelta <= 5 ? rawDelta : 0
        previousTime = now
        let wasManuallyPaused = isPaused
        pause.expire(now: Date())
        if wasManuallyPaused && !isPaused { nextSensorRead = 0 }
        if let until = watchingUntil, Date() >= until { watchingUntil = nil }
        if let until = presentationUntil, Date() >= until { presentationUntil = nil }
        idleSeconds = idle
        let decision = accounting.step(now: now, idle: idleSeconds,
            video: activeRest == nil && ((config.videoEnabled && videoPlaying) || isWatching || (config.cameraSuppression && cameraActive == true)),
            locked: suspended, paused: isPaused || pause.reasons.contains(.officeHours), resting: activeRest != nil,
            threshold: Double(config.idlePauseSeconds))
        pause.setAutomaticActivity(decision.automaticPause)
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
        statistics.sample(now: Date(), uptime: now, active: decision.activeSeconds, rollback: decision.rollback,
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
        let ready = policy.update(now: now, suppressed: suppressing, eligible: canPresent && !hasAlertProblem, due: pendingDue)
        pendingDue.removeAll()
        if suppressing { hideReminder?(); sound.stop(); notifications?.clearWeekly() }
        if !ready.isEmpty {
            reminderKinds = ready
            breakEngine.deferReminder()
            isPreview = false
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
    private func applyNaturalRest(_ duration: Double) {
        guard !credited else { return }
        let kind = nextKind
        let target = Double(BreakScheduleMath.duration(of: breakEngine.nextBreakKind, timing: breakEngine.timing))
        guard duration >= target else { return }
        if !suspended { statistics.naturalCycle(kind: kind, target: target) }
        breakEngine.accountForNaturalRest(duration)
        settings.update { $0.cycleShortCount = breakEngine.shortBreaksSinceLong }; settings.flush()
        policy.clear(kind); pendingDue.removeAll(); reminderKinds.removeAll(); credited = true
    }
    func beginRest(_ kind: MolaKind, now: Double? = nil) {
        guard !suspended else { return }
        if activeRest != nil { cancelRest() }
        statistics.beginManual()
        let selected = kind == .long ? MolaKind.long : nextKind
        activeRest = selected; restStarted = now ?? time; restReturn.reset()
        accounting.clearProvisional(); reminderKinds = [selected]; isPreview = false
        policy.clear(selected)
        if selected == .long { breakEngine.startLongBreakNow() } else { breakEngine.startBreakNow() }
        activity = .resting
        showReminder?(); play(config.breakTone); updateUI?()
    }
    func cancelRest(restartCycle: Bool = false) {
        guard let kind = activeRest else { return }
        statistics.cancelManual()
        if restartCycle { breakEngine.restartWorkCycle() }
        else { breakEngine.cancelBreakKeepingProgress() }
        policy.clear(kind); pendingDue.remove(kind)
        activeRest = nil
        breakEngine.timing = config.timing
        dismissReminder(); accounting.clearProvisional(); activity = .active; nextSensorRead = 0
        play(config.resumeTone, transition: true); updateUI?()
    }
    private func finishRest(duration: Double) {
        guard let kind = activeRest else { return }
        statistics.completeCycle(kind: kind, duration: duration)
        settings.update { $0.cycleShortCount = breakEngine.shortBreaksSinceLong }; settings.flush()
        policy.clear(kind); pendingDue.remove(kind)
        activeRest = nil; breakEngine.timing = config.timing
        dismissReminder(); accounting.clearProvisional(); activity = .active
        nextSensorRead = 0; play(config.endTone)
    }
    func dismissReminder() { reminderKinds.removeAll(); isPreview = false; hideReminder?() }
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
        pause.select(option)
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
