import AppKit
import SwiftUI

final class CursorCountdownPanel: NSPanel {
    convenience init(badgeSize: NSSize) {
        self.init(contentRect: NSRect(origin: .zero, size: badgeSize),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        title = L("Break countdown")
        setAccessibilitySubrole(.floatingWindow)
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isFloatingPanel = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        ignoresMouseEvents = true
    }
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

/// Keep the read-only accessibility element stable as SwiftUI redraws the badge.
final class CursorCountdownContentView: NSView {
    private let host: NSHostingView<CursorCountdownBadge>
    private var spokenValue: String = ""

    init(seconds: Int, kind: MolaKind, size: NSSize) {
        host = NSHostingView(rootView: CursorCountdownBadge(seconds: seconds, kind: kind))
        super.init(frame: NSRect(origin: .zero, size: size))
        host.frame = bounds
        host.autoresizingMask = [.width, .height]
        addSubview(host)
        update(seconds: seconds, kind: kind)
    }

    required init?(coder: NSCoder) { nil }

    func update(seconds: Int, kind: MolaKind) {
        host.rootView = CursorCountdownBadge(seconds: seconds, kind: kind)
        spokenValue = kind.title + ". " + String(format: L("Break in %d seconds"), seconds)
    }

    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .staticText }
    override func accessibilityValue() -> Any? { spokenValue }
    override func accessibilityChildren() -> [Any]? { [] }
}

/// A visual-only window. It never takes focus or intercepts pointer events.
final class CursorCountdownController {
    private let model: AppContainer
    private var panel: CursorCountdownPanel?
    private var content: CursorCountdownContentView?
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
            let panel = CursorCountdownPanel(badgeSize: badgeSize)
            self.panel = panel
            pointerTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        }
        if displayedSeconds != seconds || displayedKind != model.nextKind || displayedLanguage != Localization.shared.code {
            panel?.title = L("Break countdown")
            if let content { content.update(seconds: seconds, kind: model.nextKind) }
            else {
                let content = CursorCountdownContentView(seconds: seconds, kind: model.nextKind, size: badgeSize)
                self.content = content
                panel?.contentView = content
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
        panel = nil; content = nil; displayedSeconds = nil
        displayedKind = nil; displayedLanguage = nil; displayedScreen = nil; displayedVisibleFrame = nil
    }

    func stop() { hide() }
}
