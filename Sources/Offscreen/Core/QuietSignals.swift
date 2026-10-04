import Foundation

/// One current reading only. No identities, timestamps or usage history.
struct QuietSignalSnapshot {
    var audioInputActive: Bool?
    var fullScreenActive: Bool?
    var selectedAppActive: Bool?
}

enum SelectedAppPolicy {
    static let maximumApps = 32
    static func isValidID(_ id: String) -> Bool {
        let parts = id.split(separator: ".", omittingEmptySubsequences: false)
        return id.utf8.count <= 255 && parts.count >= 2 && parts.allSatisfy { part in
            !part.isEmpty && part.utf8.allSatisfy { byte in
                (65...90).contains(byte) || (97...122).contains(byte) || (48...57).contains(byte) || byte == 45
            }
        }
    }
    static func isValidSelection(_ ids: [String]) -> Bool {
        ids.count <= maximumApps && Set(ids).count == ids.count && ids.allSatisfy(isValidID)
    }
    static func normalized(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        return Array(ids.filter { isValidID($0) && seen.insert($0).inserted }.prefix(maximumApps))
    }
    static func matches(frontmostID: String?, selectedIDs: [String]) -> Bool? {
        guard let frontmostID, isValidID(frontmostID) else { return nil }
        return selectedIDs.contains(frontmostID)
    }
}

enum AudioInputPolicy {
    /// Positive evidence wins; a partial/failed query must not claim idle.
    static func aggregate(_ states: [Bool?]) -> Bool? {
        if states.contains(where: { $0 == true }) { return true }
        if states.contains(where: { $0 == nil }) { return nil }
        return false
    }
}
