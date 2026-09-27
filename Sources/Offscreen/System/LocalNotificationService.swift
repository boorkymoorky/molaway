import AppKit
import Observation
import UserNotifications

@Observable final class LocalNotificationService: NSObject, UNUserNotificationCenterDelegate {
    private weak var model: AppContainer?
    private(set) var authorization: UNAuthorizationStatus = .notDetermined
    private(set) var alertsEnabled = false
    private let center = UNUserNotificationCenter.current()
    private var token: String?
    private(set) var deliveryFailed = false
    var hasProblem: Bool { authorization != .authorized || !alertsEnabled || deliveryFailed }
    private var preview = false
    private var kind: MolaKind = .short
    init(model: AppContainer) {
        self.model = model
        super.init()
        center.delegate = self
        configureActions()
        refresh()
    }
    func configureActions() {
        let rest = UNNotificationAction(identifier: "rest", title: L("Take a break"))
        let later = UNNotificationAction(identifier: "later", title: L("Snooze 5 min"))
        center.setNotificationCategories([UNNotificationCategory(identifier: "mola.break", actions: [rest, later], intentIdentifiers: [])])
    }
    func refresh() {
        Task { [weak self] in
            guard let self else { return }
            let settings = await center.notificationSettings()
            authorization = settings.authorizationStatus
            alertsEnabled = settings.alertSetting == .enabled
            deliveryFailed = false
        }
    }
    func request() {
        Task { [weak self] in
            guard let self else { return }
            do { _ = try await center.requestAuthorization(options: [.alert, .sound]) }
            catch { model?.feedback = L("Notification permission is unavailable.") }
            refresh()
        }
    }
    func show(kind: MolaKind, combined: Bool, preview: Bool) {
        guard let model else { return }
        clear(); configureActions()
        guard authorization == .authorized && alertsEnabled else {
            model.feedback = L("Allow notifications in Privacy & permissions, or choose another alert style.")
            refresh(); return
        }
        self.kind = kind; self.preview = preview
        let token = UUID().uuidString; self.token = token
        let content = UNMutableNotificationContent()
        content.title = preview ? L("Alert preview") : kind.title
        content.body = model.reminderMessage(kind)
        content.userInfo = ["token": token]
        content.categoryIdentifier = preview ? "" : "mola.break"
        content.interruptionLevel = .active
        if model.config.reminderTone != .none {
            content.sound = model.config.reminderTone.generated
                ? UNNotificationSound(named: UNNotificationSoundName("Sounds/\(model.config.reminderTone.rawValue).wav")) : .default
        }
        center.add(UNNotificationRequest(identifier: "mola.reminder", content: content, trigger: nil)) { [weak self] error in
            if error != nil { Task { @MainActor [weak self] in
                guard let self, self.token == token else { return }
                deliveryFailed = true
                self.model?.feedback = L("Could not deliver notification.")
                if !self.preview { self.model?.notificationDeliveryFailed() }
            } }
        }
    }
    func clearWeekly() {
        center.removePendingNotificationRequests(withIdentifiers: ["molaway.weekly"])
        center.removeDeliveredNotifications(withIdentifiers: ["molaway.weekly"])
    }
    func showWeekly() {
        guard let model, model.statistics.reportDue(), model.canPresent, authorization == .authorized, alertsEnabled else { return }
        model.statistics.reportAttempted()
        guard !model.statistics.failed else { return }
        let content = UNMutableNotificationContent()
        content.title = "Molaway"
        content.body = L("Your weekly summary is ready. Open Molaway to view it.")
        content.interruptionLevel = .passive
        center.add(UNNotificationRequest(identifier: "molaway.weekly", content: content, trigger: nil)) { [weak self] error in
            Task { @MainActor [weak self] in
                guard error == nil, let self, let model = self.model else { return }
                guard model.statistics.enabled, model.statistics.weekly else { self.clearWeekly(); return }
                model.statistics.reportDelivered()
            }
        }
    }
    func clear() {
        token = nil
        center.removePendingNotificationRequests(withIdentifiers: ["mola.reminder"])
        center.removeDeliveredNotifications(withIdentifiers: ["mola.reminder"])
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        if notification.request.identifier == "molaway.weekly" {
            return await MainActor.run { [weak self] in
                guard let model = self?.model, model.statistics.enabled, model.statistics.weekly, model.canPresent else { return [] }
                return [.banner, .list]
            }
        }
        let token = notification.request.content.userInfo["token"] as? String
        return await MainActor.run { [weak self] in
            guard let self, let token, token == self.token, let model,
                  preview ? model.canPreview : model.canPresent else { return [] }
            return [.banner, .list, .sound]
        }
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let weeklyAction = response.actionIdentifier
        if response.notification.request.identifier == "molaway.weekly" {
            await MainActor.run { [weak self] in
                self?.clearWeekly()
                if weeklyAction == UNNotificationDefaultActionIdentifier, let model = self?.model,
                   model.statistics.enabled, model.statistics.weekly { model.openStatistics() }
            }
            return
        }
        let token = response.notification.request.content.userInfo["token"] as? String
        let action = response.actionIdentifier
        await MainActor.run { [weak self] in
            guard let self, let token, token == self.token, let model else { return }
            let wasPreview = preview
            clear()
            guard !wasPreview, model.canPresent else { return }
            if action == "rest" { model.beginRest(kind) }
            else if action == "later" { model.snoozeReminder() }
            else if action == UNNotificationDefaultActionIdentifier { model.openDashboardAction?() }
        }
    }
}
