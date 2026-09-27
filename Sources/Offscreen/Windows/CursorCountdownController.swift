import AppKit
import SwiftUI

private final class CursorCountdownPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private struct CursorCountdownBadge: View {
    let seconds: Int
    let kind: MolaKind

    var body: some View {
        VStack(spacing: 1) {
            Text(kind.title).font(.system(size: 10, weight: .medium))
            Text(String(format: L("%d s"), seconds))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: 116, height: 46)
        .foregroundStyle(.primary)
        .background(Color(nsColor: .windowBackgroundColor), in: Capsule())
        .overlay(Capsule().strokeBorder(.primary.opacity(0.18)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(kind.title + ". " + String(format: L("Break in %d seconds"), seconds))
    }
}

/// A visual-only window. It never takes focus or intercepts pointer events.
final class CursorCountdownController {
    private let model: AppContainer
    private var panel: CursorCountdownPanel?
    private var host: NSHostingView<CursorCountdownBadge>?
    private var pointerTimer: Timer?
    private var displayedSeconds: Int?
    private var displayedKind: MolaKind?
    private var displayedLanguage: String?
    private var displayedScreen: NSScreen?
    private var displayedVisibleFrame: NSRect?
    private let badgeSize = NSSize(width: 116, height: 46)

    init(model: AppContainer) {
        self.model = model
        let previousUpdate = model.updateUI
        model.updateUI = { [weak self] in
            previousUpdate?()
            self?.refresh()
        }
        refresh()
    }

    private func refresh() {
        guard let seconds = model.cursorCountdownSeconds,
              let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) else {
            hide(); return
        }
        if panel == nil {
            let panel = CursorCountdownPanel(contentRect: NSRect(origin: .zero, size: badgeSize),
                styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.title = L("Break countdown")
            panel.level = .statusBar
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            panel.isFloatingPanel = true
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.ignoresMouseEvents = true
            self.panel = panel
            pointerTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        }
        if displayedSeconds != seconds || displayedKind != model.nextKind || displayedLanguage != Localization.shared.code {
            let badge = CursorCountdownBadge(seconds: seconds, kind: model.nextKind)
            if let host { host.rootView = badge }
            else {
                let host = NSHostingView(rootView: badge)
                self.host = host
                panel?.contentView = host
            }
            displayedSeconds = seconds
            displayedKind = model.nextKind
            displayedLanguage = Localization.shared.code
        }
        let screenChanged = displayedScreen !== screen || displayedVisibleFrame != screen.visibleFrame
        if screenChanged || !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel?.setFrame(DisplayLayout.cursorBadgeFrame(visible: screen.visibleFrame,
                cursor: NSEvent.mouseLocation, size: badgeSize), display: true)
        }
        displayedScreen = screen
        displayedVisibleFrame = screen.visibleFrame
        if panel?.isVisible != true { panel?.orderFrontRegardless() }
    }

    private func hide() {
        pointerTimer?.invalidate(); pointerTimer = nil
        panel?.orderOut(nil); panel?.contentView = nil; panel?.close()
        panel = nil; host = nil; displayedSeconds = nil
        displayedKind = nil; displayedLanguage = nil; displayedScreen = nil; displayedVisibleFrame = nil
    }

    func stop() { hide() }
}
