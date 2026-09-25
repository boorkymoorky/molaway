import AppKit
import Observation

// MIT derivative of Offscreen's scheduler, with independent activity and reminder policies.
enum MolaKind: String, CaseIterable, Identifiable, Sendable {
    case eyes, movement
    var id: String { rawValue }
    var title: String { L(self == .eyes ? "Eye break" : "Movement break") }
    var shortTitle: String { L(self == .eyes ? "Eyes" : "Move") }
    var symbol: String { self == .eyes ? "eye" : "figure.walk" }
    var message: String { L(self == .eyes ? "Look away from the screen. Let your eyes rest." : "Stand up and take a short walk. Relax your shoulders.") }
}

@Observable final class AppContainer {
    let settings: SettingsStore
    let login = LoginItemManager()
    let sound = SoundPlayer()
    let statistics: StatisticsStore
    let eyes: BreakEngine
    let movement: BreakEngine
    private(set) var activity: ActivityState = .starting
    private(set) var videoAvailable = true
    private(set) var videoPlaying = false
    private(set) var cameraActive: Bool?
    private(set) var focusActive: Bool?
    private(set) var idleSeconds: Double = 0
    private(set) var activeRest: MolaKind?
    private(set) var pauseUntil: Date?
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
    private var suspended = false
    private let origin = ContinuousClock.now
    private var previousTime: Double?
    private var nextSensorRead = 0.0
    private var restStarted: Double = 0
    private var accounting = ActivityAccounting()
    private var policy = ReminderPolicy()
    private var credited: Set<MolaKind> = []
    private var pendingDue: Set<MolaKind> = []
    private var activityToken: NSObjectProtocol?

    init(settings: SettingsStore = SettingsStore(), statistics: StatisticsStore = StatisticsStore()) {
        self.settings = settings
        self.statistics = statistics
        eyes = BreakEngine(timing: settings.settings.eyes)
        movement = BreakEngine(timing: settings.settings.movement)
        Localization.shared.language = settings.settings.language
        applyAppearance()
        for kind in MolaKind.allCases {
            engine(kind).gentleReminders = true
            engine(kind).addListener { [weak self] event in
                guard let self else { return }
                switch event {
                case .reminderDue: pendingDue.insert(kind)
                case .breakEnded(_, .completed, let duration):
                    if activeRest == kind { finishRest(duration: duration) }
                default: break
                }
            }
        }
        settings.addListener { [weak self] value in
            guard let self else { return }
            if activeRest != .eyes { eyes.timing = value.eyes }
            if activeRest != .movement { movement.timing = value.movement }
            Localization.shared.language = value.language
            applyAppearance()
            nextSensorRead = 0
            refreshReminder?()
            updateUI?()
        }
        loginEnabled = login.isEnabled
    }
    var config: AppSettings { settings.settings }
    func engine(_ kind: MolaKind) -> BreakEngine { kind == .eyes ? eyes : movement }
    var time: Double { origin.duration(to: .now).seconds }
    var nextKind: MolaKind { eyes.timeUntilReminder <= movement.timeUntilReminder ? .eyes : .movement }
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
    var isPaused: Bool { pauseUntil != nil }
    var isWatching: Bool { watchingUntil != nil }
    var suppressionReasons: [String] {
        var reasons: [String] = []
        if presentationUntil != nil { reasons.append(L("Presentation mode")) }
        if config.cameraSuppression && cameraActive == true { reasons.append(L("Camera in use")) }
        if config.focusSuppression && focusActive == true { reasons.append(L("Focus")) }
        return reasons
    }
    var suppressing: Bool { !suppressionReasons.isEmpty }
    var canPresent: Bool { !suspended && !isPaused && !suppressing && activity != .away }
    var hasAlertProblem: Bool { config.reminderStyle == .notification && notifications?.hasProblem == true }
    func openAlertSettings() { settingsTab = 2; openSettingsAction?() }
    func notificationDeliveryFailed() { pendingDue.formUnion(reminderKinds); updateUI?() }
    func overdueLevel(_ kind: MolaKind) -> OverdueLevel {
        OverdueLevel.evaluate(enabled: config.overdueEnabled, overdue: -engine(kind).timeUntilBreak,
            snoozes: engine(kind).explicitDeferrals, amberMinutes: config.amberMinutes, redMinutes: config.redMinutes)
    }
    var visibleOverdue: OverdueLevel {
        guard !suppressing, !isPaused, activeRest == nil, [.active, .video].contains(activity) else { return .normal }
        return MolaKind.allCases.map { overdueLevel($0) }.max() ?? .normal
    }
    func reminderMessage(_ kind: MolaKind) -> String {
        guard !isPreview, activeRest == nil else { return kind.message }
        let warning = reminderKinds.union([kind]).max {
            let a = overdueLevel($0), b = overdueLevel($1)
            return a == b ? engine($0).timeUntilBreak > engine($1).timeUntilBreak : a < b
        } ?? kind
        guard overdueLevel(warning) != .normal else { return kind.message }
        let minutes = Int(max(0, -engine(warning).timeUntilBreak) / 60)
        return String(format: L("%@ has been waiting for %d minutes. Take a short break when you can."), warning.title, minutes)
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
        if let until = pauseUntil { return L("Paused until") + " " + until.formatted(date: .omitted, time: .shortened) }
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
        suspended = true
        if activeRest != nil { cancelRest(restartCycle: false) }
        statistics.resetSession(); statistics.flush(); hideReminder?(); sound.stop(); releaseActivity()
    }
    func resumeTracking(after gap: Double) {
        suspended = false
        applyNaturalRest(gap)
        previousTime = nil; nextSensorRead = 0
    }
    private func readSensors(now: Double) {
        guard !suspended else { return }
        guard now >= nextSensorRead else { return }
        nextSensorRead = now + 5
        if config.videoEnabled && !isPaused && activeRest == nil {
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
        if let until = pauseUntil, Date() >= until { pauseUntil = nil; nextSensorRead = 0 }
        if let until = watchingUntil, Date() >= until { watchingUntil = nil }
        if let until = presentationUntil, Date() >= until { presentationUntil = nil }
        idleSeconds = idle
        let decision = accounting.step(now: now, idle: idleSeconds,
            video: activeRest == nil && ((config.videoEnabled && videoPlaying) || isWatching || (config.cameraSuppression && cameraActive == true)),
            locked: suspended, paused: isPaused, resting: activeRest != nil, threshold: Double(config.idlePauseSeconds))
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
            provisional: accounting.unconfirmedSeconds, observed: isPaused || activity == .starting ? 0 : delta,
            video: config.videoEnabled && videoPlaying, watching: isWatching)
        for kind in MolaKind.allCases { engine(kind).removeProvisionalWork(decision.rollback) }
        applyNaturalRest(decision.restCredit)
        if activity == .active || activity == .video {
            credited.removeAll()
            // Keeps the timers responsive without preventing display or system sleep.
            if timer != nil && activityToken == nil { activityToken = ProcessInfo.processInfo.beginActivity(options: .userInitiatedAllowingIdleSystemSleep, reason: "Local break timer") }
            eyes.advance(by: decision.activeSeconds); movement.advance(by: decision.activeSeconds)
        } else { releaseActivity(); if !isPreview { hideReminder?(); reminderKinds.removeAll() } }
        let ready = policy.update(now: now, suppressed: suppressing, eligible: canPresent && !hasAlertProblem, due: pendingDue)
        pendingDue.removeAll()
        if suppressing { hideReminder?(); sound.stop(); notifications?.clearWeekly() }
        if !ready.isEmpty {
            reminderKinds = ready
            if config.mergeBreaks {
                for kind in MolaKind.allCases where engine(kind).timeUntilBreak <= 120 { reminderKinds.insert(kind) }
            }
            for kind in reminderKinds { engine(kind).deferReminder() }
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
        for kind in MolaKind.allCases where !credited.contains(kind) && duration >= Double(engine(kind).timing.shortBreakSeconds) {
            if !suspended { statistics.natural(kind: kind, target: Double(engine(kind).timing.shortBreakSeconds)) }
            engine(kind).accountForNaturalRest(duration); policy.clear(kind); pendingDue.remove(kind); reminderKinds.remove(kind); credited.insert(kind)
        }
    }
    func beginRest(_ kind: MolaKind, now: Double? = nil) {
        guard !suspended else { return }
        if activeRest != nil { cancelRest() }
        statistics.beginManual()
        pauseUntil = nil; activeRest = kind; restStarted = now ?? time; restReturn.reset()
        accounting.clearProvisional(); reminderKinds = [kind]; isPreview = false
        policy.clear(kind); engine(kind).startBreakNow(); activity = .resting
        showReminder?(); play(config.breakTone); updateUI?()
    }
    func cancelRest(restartCycle: Bool = true) {
        guard let kind = activeRest else { return }
        let elapsed = engine(kind).breakElapsed
        // Count only targets actually satisfied; restarting is not a completed break.
        statistics.completeManual(duration: elapsed, eyes: Double(eyes.timing.shortBreakSeconds), movement: Double(movement.timing.shortBreakSeconds))
        if restartCycle { engine(kind).restartWorkCycle() }
        else { engine(kind).cancelBreakKeepingProgress() }
        policy.clear(kind); pendingDue.remove(kind)
        for other in MolaKind.allCases where other != kind && elapsed >= Double(engine(other).timing.shortBreakSeconds) {
            engine(other).accountForNaturalRest(elapsed); policy.clear(other); pendingDue.remove(other); credited.insert(other)
        }
        activeRest = nil
        eyes.timing = config.eyes; movement.timing = config.movement
        dismissReminder(); accounting.clearProvisional(); activity = .active; nextSensorRead = 0
        play(config.resumeTone, transition: true); updateUI?()
    }
    private func finishRest(duration: Double) {
        statistics.completeManual(duration: duration, eyes: Double(eyes.timing.shortBreakSeconds), movement: Double(movement.timing.shortBreakSeconds))
        for kind in MolaKind.allCases {
            if duration >= Double(engine(kind).timing.shortBreakSeconds) { engine(kind).accountForNaturalRest(duration); policy.clear(kind); pendingDue.remove(kind) }
        }
        activeRest = nil; eyes.timing = config.eyes; movement.timing = config.movement
        dismissReminder(); accounting.clearProvisional(); activity = .active
        nextSensorRead = 0; play(config.endTone)
    }
    func dismissReminder() { reminderKinds.removeAll(); isPreview = false; hideReminder?() }
    func snoozeReminder() { for kind in reminderKinds { if !isPreview { engine(kind).recordExplicitDeferral() }; engine(kind).deferReminder() }; dismissReminder(); updateUI?() }
    func previewReminder() {
        guard canPreview else { feedback = L("End quiet mode before previewing."); return }
        isPreview = true; reminderKinds = [.eyes]; showReminder?()
        if config.reminderStyle != .notification { play(config.reminderTone) }
    }
    func togglePause() {
        if isPaused { pauseUntil = nil; nextSensorRead = 0 }
        else { statistics.resetSession(); if activeRest != nil { cancelRest() }; pauseUntil = Date().addingTimeInterval(1800); dismissReminder() }
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
