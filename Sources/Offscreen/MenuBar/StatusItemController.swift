import AppKit
import SwiftUI

final class DashboardPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    var onEscape: (() -> Void)?
    override func cancelOperation(_ sender: Any?) { onEscape?() }
}

final class StatusItemController: NSObject, NSWindowDelegate {
    private let model: AppContainer
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var dashboard: NSPanel?
    private var screenToken: NSObjectProtocol?
    private var dashboardLayoutKey = ""
    private var lastRingKey = ""

    init(model: AppContainer) {
        self.model = model
        super.init()
        screenToken = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { if let window = self?.dashboard { ScreenPlacement.recover(window); self?.refreshDashboardLayout(force: true) } }
        }
        if let button = item.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            button.setAccessibilityLabel(L("Molaway · short and long breaks"))
        }
        model.openDashboardAction = { [weak self] in self?.toggle() }
        model.updateUI = { [weak self] in self?.refresh() }
        refresh()
    }

    func refresh() {
        guard let button = item.button else { return }
        refreshDashboardLayout()
        let paused = [.away, .sleeping, .paused, .starting].contains(model.activity)
        let progress = model.ringProgress
        let ringKey = "\(Int(progress.outer * 100))-\(Int((progress.inner ?? -1) * 100))-\(indicator)-\(model.visibleOverdue.rawValue)"
        if ringKey != lastRingKey { button.image = ringImage(); lastRingKey = ringKey }
        let readout = model.nextReadout
        let text = paused ? "" : readout.menuText
        let title = MenuTitle.make(show: model.config.showCountdownInMenuBar, paused: paused, countdown: text)
        if button.title != title { button.title = title }
        let cadence = model.config.shortBreaksBeforeLong > 0
            ? String(format: L("%d of %d short breaks completed"),
                     min(model.breakEngine.shortBreaksSinceLong, model.config.shortBreaksBeforeLong), model.config.shortBreaksBeforeLong)
            : L("Long breaks off")
        let hint = model.statusText + "\n" + L(readout.resting ? "Rest time" : readout.deferred ? "Next reminder" : "Next break") + ": " + readout.kind.title + " · " + readout.clock
            + "\n" + L("Outer ring") + ": " + L(readout.resting ? "Rest progress" : "Work progress") + " \(Int((progress.outer * 100).rounded()))%"
            + "\n" + L("Inner ring") + ": " + cadence
        if button.toolTip != hint { button.toolTip = hint; button.setAccessibilityValue(hint) }
        let label = L("Molaway · short and long breaks")
        if button.accessibilityLabel() != label { button.setAccessibilityLabel(label) }
    }

    private var indicator: String {
        if [.away, .sleeping, .paused, .starting].contains(model.activity) { return "pause.fill" }
        if model.activeRest != nil { return "leaf.fill" }
        if model.suppressing { return "bell.slash.fill" }
        if model.hasAlertProblem || model.visibleOverdue != .normal { return "exclamationmark" }
        return ""
    }
    private func ringImage() -> NSImage {
        let progress = model.ringProgress
        let glyph = indicator
        let level = model.visibleOverdue
        let ink: NSColor = level == .red ? .systemRed : level == .amber ? .systemOrange : .black
        let image = NSImage(size: NSSize(width: 20, height: 20), flipped: false) { _ in
            var rings: [(Double, Double)] = [(8.0, progress.outer)]
            if let inner = progress.inner { rings.append((4.7, inner)) }
            for (radius, fraction) in rings {
                let start = radius == 8 ? 45.0 : 225.0
                let background = NSBezierPath()
                background.appendArc(withCenter: NSPoint(x: 10, y: 10), radius: radius, startAngle: start, endAngle: start - 270, clockwise: true)
                ink.withAlphaComponent(0.3).setStroke()
                background.lineWidth = 1.6; background.lineCapStyle = .round
                background.stroke()
                if fraction > 0 {
                    let arc = NSBezierPath()
                    arc.appendArc(withCenter: NSPoint(x: 10, y: 10), radius: radius,
                                  startAngle: start, endAngle: start - 270 * max(0.02, fraction), clockwise: true)
                    ink.setStroke(); arc.lineWidth = 1.8; arc.lineCapStyle = .round; arc.stroke()
                }
            }
            if !glyph.isEmpty {
                let symbol = NSImage(systemSymbolName: glyph, accessibilityDescription: nil)?.withSymbolConfiguration(.init(paletteColors: [ink]))
                symbol?.draw(in: NSRect(x: 5, y: 5, width: 10, height: 10))
            }
            return true
        }
        image.isTemplate = level == .normal
        return image
    }

    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp { showContextMenu() } else { toggle() }
    }
    private func toggle() {
        if dashboard != nil { closeDashboard(); return }
        guard let screen = ScreenPlacement.underPointer() else { return }
        let anchor = NSEvent.mouseLocation
        let measured = NSHostingView(rootView: DashboardView(model: model)).fittingSize
        let height = min(measured.height, max(1, screen.visibleFrame.height - 32))
        let panel = DashboardPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = "Molaway"; panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true; panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.backgroundColor = .clear; panel.isOpaque = false; panel.hasShadow = true
        panel.delegate = self
        panel.onEscape = { [weak self] in self?.closeDashboard() }
        let host = NSHostingView(rootView: ScrollView { DashboardView(model: model) }
            .frame(width: 342, height: height).background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 18))
            .clipShape(RoundedRectangle(cornerRadius: 18)))
        panel.contentView = host
        panel.setFrame(DisplayLayout.dashboardFrame(visible: screen.visibleFrame, anchor: anchor, size: NSSize(width: 342, height: height)), display: true)
        dashboard = panel; dashboardLayoutKey = layoutKey
        panel.orderFrontRegardless(); panel.makeKey()
    }
    private var layoutKey: String {
        "\(model.statusText)|\(model.isWatching)|\(model.presentationUntil != nil)|\(model.activeRest?.rawValue ?? "")|\(model.config.shortBreaksBeforeLong)|\(model.hasAlertProblem)|\(Localization.shared.code)|\(model.visibleOverdue.rawValue)"
    }
    private func refreshDashboardLayout(force: Bool = false) {
        guard let panel = dashboard, let screen = panel.screen, (force || layoutKey != dashboardLayoutKey) else { return }
        dashboardLayoutKey = layoutKey
        let measured = NSHostingView(rootView: DashboardView(model: model)).fittingSize
        let height = min(measured.height, max(1, screen.visibleFrame.height - 32))
        panel.contentView = NSHostingView(rootView: ScrollView { DashboardView(model: model) }
            .frame(width: 342, height: height).background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 18))
            .clipShape(RoundedRectangle(cornerRadius: 18)))
        panel.setFrame(DisplayLayout.dashboardFrame(visible: screen.visibleFrame, anchor: NSPoint(x: panel.frame.midX, y: screen.visibleFrame.maxY), size: NSSize(width: 342, height: height)), display: true)
    }
    func windowDidResignKey(_ notification: Notification) { closeDashboard() }
    private func closeDashboard() {
        let old = dashboard; dashboard = nil
        old?.delegate = nil; old?.orderOut(nil); old?.contentView = nil; old?.close()
    }
    @objc private func pauseAction() { model.togglePause() }
    @objc private func watchingAction() { model.toggleWatching() }
    @objc private func presentationAction() { model.togglePresentation() }
    @objc private func settingsAction() { model.openSettingsAction?() }
    @objc private func quitAction() { NSApp.terminate(nil) }
    private func showContextMenu() {
        closeDashboard()
        let menu = NSMenu()
        for (title, action) in [(model.isPaused ? L("Resume tracking") : L("Pause 30 min"), #selector(pauseAction)),
                                (L(model.isWatching ? "End watching" : "Watching mode"), #selector(watchingAction)),
                                (L(model.presentationUntil == nil ? "Presentation" : "End presentation"), #selector(presentationAction)),
                                (L("Settings"), #selector(settingsAction)), (L("Quit Molaway"), #selector(quitAction))] {
            let entry = NSMenuItem(title: title, action: action, keyEquivalent: "")
            entry.target = self; menu.addItem(entry)
        }
        let point = NSEvent.mouseLocation
        // AppKit positions the native menu at the actual click, including mirrored menu bars.
        menu.popUp(positioning: nil, at: point, in: nil)
    }
    func stop() {
        closeDashboard()
        if let screenToken { NotificationCenter.default.removeObserver(screenToken) }; screenToken = nil
    }
}
