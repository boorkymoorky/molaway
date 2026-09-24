import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var container: AppContainer?
    private var status: StatusItemController?
    private var reminder: PreBreakPanelController?
    private var settingsWindow: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let container = AppContainer()
        self.container = container
        let settings = SettingsWindowController(model: container)
        settingsWindow = settings
        container.openSettingsAction = { [weak settings] in settings?.show() }
        status = StatusItemController(model: container)
        reminder = PreBreakPanelController(model: container)
        container.start()
        if !container.settings.settings.didFinishWelcome {
            container.settings.update { $0.didFinishWelcome = true }
            settings.show()
        }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindow?.show()
        return true
    }
    func applicationDidBecomeActive(_ notification: Notification) { container?.notifications?.refresh() }
    func applicationWillTerminate(_ notification: Notification) { reminder?.stop(); status?.stop(); settingsWindow?.stop(); container?.stop() }
}
