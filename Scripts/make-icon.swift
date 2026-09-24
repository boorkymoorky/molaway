// Original vector artwork for Molaway. No fonts, third-party assets or network.
import AppKit

@main struct MakeIcon {
    static func main() throws {
        let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for size in [16, 32, 64, 128, 256, 512, 1024] {
            let space = CGColorSpace(name: CGColorSpace.sRGB)!
            let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                                space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
            let box = CGRect(x: 82, y: 82, width: 860, height: 860)
            let tile = CGPath(roundedRect: box, cornerWidth: 190, cornerHeight: 190, transform: nil)
            ctx.saveGState(); ctx.setShadow(offset: CGSize(width: 0, height: -9), blur: 22, color: NSColor.black.withAlphaComponent(0.22).cgColor)
            ctx.setFillColor(NSColor(srgbRed: 0.06, green: 0.29, blue: 0.28, alpha: 1).cgColor); ctx.addPath(tile); ctx.fillPath(); ctx.restoreGState()
            ctx.saveGState(); ctx.addPath(tile); ctx.clip()
            let colors = [NSColor(srgbRed: 0.20, green: 0.57, blue: 0.49, alpha: 1).cgColor,
                          NSColor(srgbRed: 0.04, green: 0.25, blue: 0.25, alpha: 1).cgColor]
            ctx.drawLinearGradient(CGGradient(colorsSpace: space, colors: colors as CFArray, locations: [0,1])!,
                                   start: CGPoint(x: 130,y: 950), end: CGPoint(x: 860,y: 80), options: [])
            ctx.restoreGState()
            ctx.addPath(tile); ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.16).cgColor); ctx.setLineWidth(3); ctx.strokePath()
            ctx.translateBy(x: 0, y: 1024); ctx.scaleBy(x: 1, y: -1)
            ctx.addPath(BrandGeometry.path(in: CGRect(x: 122, y: 122, width: 780, height: 780)))
            ctx.setLineWidth(58.5); ctx.setLineCap(.round)
            ctx.setStrokeColor(NSColor(srgbRed: 0.87, green: 0.98, blue: 0.93, alpha: 1).cgColor); ctx.strokePath()
            let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
            try rep.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("icon-\(size).png"))
        }
    }
}
