import CoreMediaIO
import Intents

/// Device-state queries only. Never creates a capture session or requests camera access.
enum CameraStateMonitor {
    static func read() -> Bool? {
        var address = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices), mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal), mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        var size: UInt32 = 0
        let system = CMIOObjectID(kCMIOObjectSystemObject)
        guard CMIOObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr,
              size > 0, size <= 4096, size % 4 == 0 else { return nil }
        var devices = [CMIOObjectID](repeating: 0, count: Int(size) / 4)
        let result = devices.withUnsafeMutableBytes { bytes in
            CMIOObjectGetPropertyData(system, &address, 0, nil, size, &size, bytes.baseAddress!)
        }
        guard result == noErr else { return nil }
        var anyReadable = false
        for device in devices {
            var runningAddress = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere), mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal), mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
            var running: UInt32 = 0
            var used: UInt32 = 0
            if CMIOObjectGetPropertyData(device, &runningAddress, 0, nil, 4, &used, &running) == noErr {
                anyReadable = true
                if running != 0 { return true }
            }
        }
        return anyReadable ? false : nil
    }
}
enum FocusMonitor {
    static var status: INFocusStatusAuthorizationStatus { INFocusStatusCenter.default.authorizationStatus }
    static func read() -> Bool? {
        guard status == .authorized else { return nil }
        return INFocusStatusCenter.default.focusStatus.isFocused
    }
    static func request(_ completion: @escaping @MainActor @Sendable () -> Void) {
        INFocusStatusCenter.default.requestAuthorization { _ in Task { @MainActor in completion() } }
    }
}
