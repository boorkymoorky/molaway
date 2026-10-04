import AppKit

enum StatusItemImage {
    static func make(progress: RingProgress, symbol glyph: String, level: OverdueLevel) -> NSImage {
        let ink: NSColor = level == .red ? .systemRed : level == .amber ? .systemOrange : .black
        let image = NSImage(size: NSSize(width: 20, height: 20), flipped: false) { _ in
            // Keep a drawable image with stable dimensions when the countdown title disappears.
            if glyph == "pause.fill" {
                ink.setFill()
                for x in [6.0, 11.0] {
                    NSBezierPath(roundedRect: NSRect(x: x, y: 4.5, width: 3, height: 11),
                                 xRadius: 0.6, yRadius: 0.6).fill()
                }
                return true
            }
            if !glyph.isEmpty {
                if let symbol = NSImage(systemSymbolName: glyph, accessibilityDescription: nil)?
                    .withSymbolConfiguration(.init(paletteColors: [ink])) {
                    symbol.draw(in: NSRect(x: 2, y: 2, width: 16, height: 16))
                } else {
                    ink.setFill()
                    NSBezierPath(ovalIn: NSRect(x: 7, y: 7, width: 6, height: 6)).fill()
                }
                return true
            }
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
            return true
        }
        image.isTemplate = level == .normal
        return image
    }

}
