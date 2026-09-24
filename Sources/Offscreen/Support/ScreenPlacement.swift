import AppKit

enum ScreenPlacement {
    static func underPointer() -> NSScreen? {
        NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main ?? NSScreen.screens.first
    }
    static func recover(_ window: NSWindow) {
        let screens = NSScreen.screens
        guard let screen = screens.max(by: {
            let a = $0.visibleFrame.intersection(window.frame)
            let b = $1.visibleFrame.intersection(window.frame)
            return (a.isNull ? 0 : a.width * a.height) < (b.isNull ? 0 : b.width * b.height)
        }) else { return }
        window.setFrame(DisplayLayout.windowFrame(current: window.frame, visible: screen.visibleFrame, centered: false), display: true)
    }
}
