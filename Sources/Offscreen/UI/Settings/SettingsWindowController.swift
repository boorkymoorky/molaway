import AppKit
import SwiftUI

final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let model: AppContainer
    private var window: NSWindow?
    private var screenToken: NSObjectProtocol?
    init(model: AppContainer) {
        self.model = model; super.init()
        screenToken = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { if let window = self?.window { ScreenPlacement.recover(window) } }
        }
    }
    func stop() { if let screenToken { NotificationCenter.default.removeObserver(screenToken) }; screenToken = nil }

    func show() {
        let target = (NSApp.keyWindow is DashboardPanel ? NSApp.keyWindow?.screen : nil) ?? ScreenPlacement.underPointer()
        let creating = window == nil
        if window == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 780, height: 660),
                                  styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            window.title = "Molaway"
            window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.contentView = NSHostingView(rootView: SettingsRootView(model: model))
            window.contentMinSize = NSSize(width: 600, height: 440)
            self.window = window
        }
        if window?.contentView == nil { window?.contentView = NSHostingView(rootView: SettingsRootView(model: model)) }
        if let window, let target {
            let onTarget = target.frame.contains(NSPoint(x: window.frame.midX, y: window.frame.midY))
            window.setFrame(DisplayLayout.windowFrame(current: window.frame, visible: target.visibleFrame, centered: creating || !onTarget), display: true)
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
    func windowWillClose(_ notification: Notification) { window?.contentView = nil }
}
