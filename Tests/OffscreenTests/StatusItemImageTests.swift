import AppKit
import Testing
@testable import Offscreen

@Suite struct StatusItemImageTests {
    private func pixels(_ image: NSImage) throws -> NSBitmapImageRep {
        let bitmap = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 20, pixelsHigh: 20,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let context = try #require(NSGraphicsContext(bitmapImageRep: bitmap))
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = context
        image.draw(in: NSRect(x: 0, y: 0, width: 20, height: 20))
        return bitmap
    }
    private var progress: RingProgress {
        .init(workAccrued: 600, workSeconds: 1200, restRemaining: nil, restDuration: nil,
              completedShorts: 2, shortsBeforeLong: 3)
    }
    @Test func pausedImageRendersTwoVisibleBarsWithoutRings() throws {
        let image = StatusItemImage.make(progress: progress, symbol: "pause.fill", level: .normal)
        #expect(image.size == NSSize(width: 20, height: 20))
        let bitmap = try pixels(image)
        var runs = 0
        var previous = false
        for x in 0..<20 {
            let visible = (bitmap.colorAt(x: x, y: 10)?.alphaComponent ?? 0) > 0.5
            if visible && !previous { runs += 1 }
            previous = visible
        }
        #expect(runs == 2)
        #expect((bitmap.colorAt(x: 1, y: 10)?.alphaComponent ?? 0) < 0.1)
        #expect((bitmap.colorAt(x: 18, y: 10)?.alphaComponent ?? 0) < 0.1)
        #expect(image.isTemplate)
    }
    @Test func everyMenuStateHasVisiblePixels() throws {
        for symbol in ["", "pause.fill", "leaf.fill", "bell.slash.fill", "exclamationmark"] {
            for level in [OverdueLevel.normal, .amber, .red] {
                let bitmap = try pixels(StatusItemImage.make(progress: progress, symbol: symbol, level: level))
                var visible = 0
                for x in 0..<20 {
                    for y in 0..<20 {
                        if (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.1 { visible += 1 }
                    }
                }
                #expect(visible > 10, "Empty status image: \(symbol), \(level)")
            }
        }
    }
}
