import AppKit
import CoreAudio

enum QuietSignalMonitor {
    static func read(config: AppSettings) -> QuietSignalSnapshot {
        QuietSignalSnapshot(
            audioInputActive: config.audioInputSuppression ? AudioInputStateMonitor.read() : nil,
            fullScreenActive: config.fullScreenSuppression ? nativeFullScreen(NSApp?.currentSystemPresentationOptions) : nil,
            selectedAppActive: config.selectedAppSuppression && !config.selectedAppBundleIDs.isEmpty
                ? SelectedAppPolicy.matches(frontmostID: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
                                            selectedIDs: config.selectedAppBundleIDs) : nil)
    }

    static func nativeFullScreen(_ options: NSApplication.PresentationOptions?) -> Bool? {
        options.map { $0.contains(.fullScreen) }
    }
}

/// Public input-stream state only. No audio IO, tap, capture session, PID,
/// bundle identity, device name or sound samples are requested.
enum AudioInputStateMonitor {
    static func read() -> Bool? {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        let system = AudioObjectID(kAudioObjectSystemObject)
        var size: UInt32 = 0
        let stride = UInt32(MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr,
              size <= 16_384, size % stride == 0 else { return nil }
        if size == 0 { return false }
        let capacity = size
        var objects = [AudioObjectID](repeating: 0, count: Int(size / stride))
        let result = objects.withUnsafeMutableBytes {
            AudioObjectGetPropertyData(system, &address, 0, nil, &size, $0.baseAddress!)
        }
        guard result == noErr, size <= capacity, size % stride == 0 else { return nil }
        // Use only returned entries if the list shrank during the query.
        var states: [Bool?] = []
        for object in objects.prefix(Int(size / stride)) {
            var runningAddress = AudioObjectPropertyAddress(mSelector: kAudioProcessPropertyIsRunningInput,
                mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
            var running: UInt32 = 0
            var used = UInt32(MemoryLayout<UInt32>.size)
            let status = AudioObjectGetPropertyData(object, &runningAddress, 0, nil, &used, &running)
            let state: Bool? = status == noErr && used == 4 && running <= 1 ? running == 1 : nil
            if state == true { return true }
            states.append(state)
        }
        return AudioInputPolicy.aggregate(states)
    }
}
