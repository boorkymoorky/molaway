import Foundation

enum QuietReason: String {
    case presentation = "Presentation mode"
    case camera = "Camera in use"
    case focus = "Focus"
    case audioInput = "Audio input in use"
    case fullScreen = "Native full screen"
    case selectedApp = "Selected app in front"
}

/// Activity and quiet-alert effects remain separate. M8 signals only quiet
/// alerts; they never infer presence, prevent idle, or credit a break.
struct SmartPause {
    let keepsCounting: Bool
    let quietReasons: [QuietReason]

    init(config: AppSettings, videoPlaying: Bool, watching: Bool,
         cameraActive: Bool?, focusActive: Bool?, presenting: Bool,
         audioInputActive: Bool? = nil, fullScreenActive: Bool? = nil, selectedAppActive: Bool? = nil) {
        let camera = config.cameraSuppression && cameraActive == true
        keepsCounting = (config.videoEnabled && videoPlaying) || watching || camera
        var reasons: [QuietReason] = []
        if presenting { reasons.append(.presentation) }
        if camera { reasons.append(.camera) }
        if config.focusSuppression && focusActive == true { reasons.append(.focus) }
        if config.audioInputSuppression && audioInputActive == true { reasons.append(.audioInput) }
        if config.fullScreenSuppression && fullScreenActive == true { reasons.append(.fullScreen) }
        if config.selectedAppSuppression && !config.selectedAppBundleIDs.isEmpty && selectedAppActive == true { reasons.append(.selectedApp) }
        quietReasons = reasons
    }
}

/// One bounded budget per due work cycle, including retries. Only transient
/// elapsed times are held; never keys, counts, text or an activity history.
struct TypingDeferral {
    static let maximumSeconds: Double = 30
    static let quietSeconds: Double = 2
    private var startedAt: Double?
    private var spent = false
    private var lastTime: Double?

    mutating func reset() { self = TypingDeferral() }

    mutating func update(now: Double, cycleDue: Bool, pending: Bool, eligible: Bool,
                         enabled: Bool, keyboardIdle: Double?) -> Double? {
        guard cycleDue else { reset(); return nil }
        guard now.isFinite, lastTime.map({ now >= $0 }) ?? true else {
            spent = true
            return nil
        }
        lastTime = now
        guard enabled else {
            if startedAt != nil { spent = true }
            return nil
        }
        guard !spent else { return nil }
        if let startedAt, now - startedAt >= Self.maximumSeconds {
            spent = true
            return nil
        }
        guard eligible, pending else { return nil }
        guard let keyboardIdle, keyboardIdle.isFinite, keyboardIdle >= 0,
              keyboardIdle < Self.quietSeconds else {
            spent = true
            return nil
        }
        if startedAt == nil { startedAt = now }
        return max(0, Self.maximumSeconds - (now - (startedAt ?? now)))
    }
}
