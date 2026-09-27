import AppKit
import SwiftUI

final class ReminderPanel: NSPanel {
    var onEscape: (() -> Void)?
    var onInteraction: (() -> Void)?
    var acceptsKeys = false
    override var canBecomeKey: Bool { acceptsKeys }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) { onEscape?() }
    override func keyDown(with event: NSEvent) {
        onInteraction?()
        if event.keyCode == 53 { onEscape?() } else { super.keyDown(with: event) }
    }
}

/// One interactive panel per chosen display, without creating or switching Spaces.
final class PreBreakPanelController {
    private let model: AppContainer
    private var panels: [ReminderPanel] = []
    private var retiring: [ReminderPanel] = []
    private var dismissal: Timer?
    private var hovered = Set<ObjectIdentifier>()
    private var shownStyle: ReminderStyle?
    private var shownTarget: DisplayTarget?
    private var screenToken: NSObjectProtocol?
    init(model: AppContainer) {
        self.model = model
        model.notifications = LocalNotificationService(model: model)
        model.showReminder = { [weak self] in self?.show() }
        model.hideReminder = { [weak self] in guard let self else { return }; hide(animated: self.model.canPreview) }
        model.refreshReminder = { [weak self] in self?.refresh() }
        screenToken = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { if let self, self.panels.contains(where: \.isVisible) { self.show() } }
        }
    }
    private func screens() -> [NSScreen] {
        let screens = NSScreen.screens
        return DisplayLayout.selectedIndices(frames: screens.map(\.frame), cursor: NSEvent.mouseLocation, target: model.config.displayTarget).map { screens[$0] }
    }
    private func refresh() {
        guard shownStyle != nil else { return }
        guard !model.suppressing else { hide(animated: false); return }
        if shownStyle != model.config.reminderStyle || shownTarget != model.config.displayTarget {
            show(); return
        }
        for panel in panels {
            guard let screen = panel.screen else { continue }
            panel.contentView?.layoutSubtreeIfNeeded()
            if model.config.reminderStyle != .fullScreen, let size = panel.contentView?.fittingSize {
                panel.setFrame(DisplayLayout.panelFrame(visible: screen.visibleFrame, desired: size, centered: model.config.reminderStyle == .banner), display: true)
            }
        }
    }
    func show() {
        hide(animated: false)
        shownStyle = model.config.reminderStyle; shownTarget = model.config.displayTarget
        if model.config.reminderStyle == .notification && model.activeRest == nil {
            model.notifications?.show(kind: model.nextKind, combined: model.reminderKinds.count > 1, preview: model.isPreview)
            if model.isPreview { scheduleDismissal() }
            return
        }
        let style = model.config.reminderStyle == .notification ? ReminderStyle.corner : model.config.reminderStyle
        let full = style == .fullScreen
        for screen in screens() {
            let panel = ReminderPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.title = L("Molaway reminder")
            panel.level = .statusBar
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            panel.isFloatingPanel = true; panel.hidesOnDeactivate = false
            panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = !full
            panel.isReleasedWhenClosed = false; panel.acceptsKeys = true
            panel.onEscape = { [weak model] in
                model?.dismissReminder()
            }
            panel.onInteraction = { [weak self] in self?.scheduleDismissal() }
            let id = ObjectIdentifier(panel)
            let view = NSHostingView(rootView: PreBreakView(model: model, style: style, availableSize: screen.visibleFrame.size) { [weak self] inside in
                guard let self else { return }
                if inside { hovered.insert(id); dismissal?.invalidate(); dismissal = nil }
                else { hovered.remove(id); if hovered.isEmpty { scheduleDismissal() } }
            })
            panel.contentView = view
            if full { panel.setFrame(screen.frame, display: true) }
            else { panel.setFrame(DisplayLayout.panelFrame(visible: screen.visibleFrame, desired: view.fittingSize, centered: style == .banner), display: true) }
            panels.append(panel)
            let animate = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            let final = panel.frame
            if animate {
                panel.alphaValue = 0
                if style == .banner { panel.setFrameOrigin(NSPoint(x: final.minX, y: final.minY + 10)) }
            }
            panel.orderFrontRegardless()
            if full && screen.frame.contains(NSEvent.mouseLocation) { panel.makeKey() }
            if animate {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    panel.animator().setFrame(final, display: true); panel.animator().alphaValue = 1
                }
            }
        }
        if full && !panels.contains(where: \.isKeyWindow) { panels.first?.makeKey() }
        scheduleDismissal()
    }
    private func scheduleDismissal() {
        dismissal?.invalidate(); dismissal = nil
        guard model.activeRest == nil, hovered.isEmpty, shownStyle != nil else { return }
        dismissal = Timer.scheduledTimer(withTimeInterval: Double(model.config.reminderVisibleSeconds), repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.dismissReminder() }
        }
    }
    func hide(animated: Bool = false) {
        dismissal?.invalidate(); dismissal = nil; hovered.removeAll()
        shownStyle = nil; shownTarget = nil
        for panel in retiring { panel.orderOut(nil); panel.close() }; retiring.removeAll()
        let old = panels; panels.removeAll(); model.notifications?.clear()
        guard animated, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion, !old.isEmpty else {
            for panel in old { panel.orderOut(nil); panel.contentView = nil; panel.close() }; return
        }
        retiring = old
        for panel in old { panel.ignoresMouseEvents = true }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            for panel in old { panel.animator().alphaValue = 0 }
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                for panel in old { panel.orderOut(nil); panel.contentView = nil; panel.close() }
                self?.retiring.removeAll { panel in old.contains(where: { $0 === panel }) }
            }
        }
    }
    func stop() { hide(); if let screenToken { NotificationCenter.default.removeObserver(screenToken) }; screenToken = nil }
}
