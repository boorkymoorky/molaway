import Foundation
import Observation
import UserNotifications

/// Keeps a failed request distinct from a permission that has never been requested.
@Observable final class NotificationPermission {
    struct Snapshot {
        let authorization: UNAuthorizationStatus
        let alertsEnabled: Bool
    }
    enum Failure { case rejected, unavailable }
    private(set) var authorization: UNAuthorizationStatus = .notDetermined
    private(set) var alertsEnabled = false
    private(set) var failure: Failure?
    private(set) var isRequesting = false
    private var revision = 0
    private let read: () async -> Snapshot
    private let authorize: () async throws -> Void

    init(read: @escaping () async -> Snapshot, authorize: @escaping () async throws -> Void) {
        self.read = read; self.authorize = authorize
    }
    var statusKey: String {
        switch authorization {
        case .authorized: alertsEnabled ? "Allowed" : "Banners disabled"
        case .denied: "Denied in System Settings"
        case .notDetermined: failure == nil ? "Not requested" : "Could not request permission"
        default: "Unavailable"
        }
    }
    var failureKey: String? {
        guard authorization == .notDetermined else { return nil }
        return switch failure {
        case .rejected: "macOS did not allow this copy of Molaway to request notifications. Choose a panel alert instead."
        case .unavailable: "macOS could not request notification permission. Try again, or choose a panel alert."
        case nil: nil
        }
    }
    func refresh() async {
        guard !isRequesting else { return }
        revision += 1
        let current = revision
        let snapshot = await read()
        guard revision == current else { return }
        apply(snapshot)
    }
    func request() async {
        guard !isRequesting else { return }
        isRequesting = true
        revision += 1 // An earlier refresh must not overwrite the request's result.
        defer { isRequesting = false }
        failure = nil
        do { try await authorize() }
        catch {
            let error = error as NSError
            failure = error.domain == UNErrorDomain && error.code == UNError.Code.notificationsNotAllowed.rawValue
                ? .rejected : .unavailable
        }
        apply(await read())
    }
    private func apply(_ snapshot: Snapshot) {
        authorization = snapshot.authorization
        alertsEnabled = snapshot.alertsEnabled
        if authorization != .notDetermined { failure = nil }
    }
}
