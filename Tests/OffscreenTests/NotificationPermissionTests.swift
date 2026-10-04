import Foundation
import Testing
import UserNotifications
@testable import Offscreen

@Suite struct NotificationPermissionTests {
    @Test func failedRequestSurvivesRefreshAndSuccessfulRetryClearsIt() async {
        var snapshot = NotificationPermission.Snapshot(authorization: .notDetermined, alertsEnabled: false)
        var fails = true
        let permission = NotificationPermission(read: { snapshot }, authorize: {
            if fails { throw NSError(domain: UNErrorDomain, code: UNError.Code.notificationsNotAllowed.rawValue) }
            snapshot = .init(authorization: .authorized, alertsEnabled: true)
        })
        #expect(permission.statusKey == "Not requested")
        await permission.request()
        #expect(permission.failure == .rejected)
        #expect(permission.statusKey == "Could not request permission")
        #expect(permission.failureKey != nil)
        await permission.refresh()
        #expect(permission.statusKey == "Could not request permission")
        fails = false
        await permission.request()
        #expect(permission.authorization == .authorized && permission.alertsEnabled)
        #expect(permission.statusKey == "Allowed" && permission.failureKey == nil)
    }
    @Test func denialIsNotReportedAsRequestFailure() async {
        let permission = NotificationPermission(read: { .init(authorization: .denied, alertsEnabled: false) }, authorize: {})
        await permission.request()
        #expect(permission.statusKey == "Denied in System Settings")
        #expect(permission.failure == nil && permission.failureKey == nil)
    }
    @Test func genericErrorDoesNotExposeSystemDetails() async {
        let permission = NotificationPermission(read: { .init(authorization: .notDetermined, alertsEnabled: false) }, authorize: {
            throw NSError(domain: "test.private", code: 99, userInfo: [NSLocalizedDescriptionKey: "private diagnostic"])
        })
        await permission.request()
        #expect(permission.failure == .unavailable)
        #expect(permission.failureKey == "macOS could not request notification permission. Try again, or choose a panel alert.")
    }
    @Test func externalPermissionChangeClearsFailureAndReportsDisabledBanners() async {
        var snapshot = NotificationPermission.Snapshot(authorization: .notDetermined, alertsEnabled: false)
        let permission = NotificationPermission(read: { snapshot }, authorize: { throw NSError(domain: "test", code: 1) })
        await permission.request()
        snapshot = .init(authorization: .authorized, alertsEnabled: false)
        await permission.refresh()
        #expect(permission.failure == nil && permission.statusKey == "Banners disabled")
    }
    @Test func staleRefreshCannotOverwriteCompletedRequest() async {
        var olderRead: CheckedContinuation<NotificationPermission.Snapshot, Never>?
        var reads = 0
        let permission = NotificationPermission(read: {
            reads += 1
            if reads == 1 { return await withCheckedContinuation { olderRead = $0 } }
            return .init(authorization: .authorized, alertsEnabled: true)
        }, authorize: {})
        let refresh = Task { await permission.refresh() }
        while olderRead == nil { await Task.yield() }
        await permission.request()
        olderRead?.resume(returning: .init(authorization: .notDetermined, alertsEnabled: false))
        await refresh.value
        #expect(permission.authorization == .authorized && permission.alertsEnabled)
    }
    @Test func duplicateRequestAndRefreshAreIgnoredWhilePromptIsPending() async {
        var pending: CheckedContinuation<Void, Never>?
        var requests = 0
        var reads = 0
        let permission = NotificationPermission(read: {
            reads += 1
            return .init(authorization: .authorized, alertsEnabled: true)
        }, authorize: {
            requests += 1
            await withCheckedContinuation { pending = $0 }
        })
        let request = Task { await permission.request() }
        while pending == nil { await Task.yield() }
        #expect(permission.isRequesting)
        await permission.request()
        await permission.refresh()
        #expect(requests == 1 && reads == 0)
        pending?.resume()
        await request.value
        #expect(!permission.isRequesting && reads == 1)
    }
}
