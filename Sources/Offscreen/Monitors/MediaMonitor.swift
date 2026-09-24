import AppKit
import IOKit.pwr_mgt

/// Reads only transient power assertions. No media, URLs or window contents.
enum MediaMonitor {
    struct Reading { var isPlaying: Bool; var available: Bool }
    static func read() -> Reading {
        var result: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&result) == kIOReturnSuccess,
              let data = result?.takeRetainedValue() as? [NSNumber: [[String: Any]]] else {
            return Reading(isPlaying: false, available: false)
        }
        for assertions in data.values {
            for assertion in assertions where MediaRule.matches(
                name: assertion[kIOPMAssertionNameKey] as? String ?? "",
                type: assertion[kIOPMAssertionTypeKey] as? String ?? "",
                level: (assertion[kIOPMAssertionLevelKey] as? NSNumber)?.intValue ?? 0) {
                return Reading(isPlaying: true, available: true)
            }
        }
        return Reading(isPlaying: false, available: true)
    }
}
enum MediaRule {
    static func matches(name: String, type: String, level: Int) -> Bool {
        guard level > 0, ["PreventUserIdleDisplaySleep", "NoDisplaySleepAssertion"].contains(type) else { return false }
        return ["video wake lock", "playing video", "video playback", "video-playing"].contains(name.lowercased())
    }
}
