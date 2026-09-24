import Foundation
import CoreGraphics

/// Original Molaway mark: two open rings with opposite breathing spaces.
enum BrandGeometry {
    static func path(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.addPath(ring(in: rect, outer: true))
        path.addPath(ring(in: rect, outer: false))
        return path
    }
    static func ring(in rect: CGRect, outer: Bool, progress: Double = 1) -> CGPath {
        let path = CGMutablePath(), scale = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = outer ? 0.36 : 0.21, start = outer ? -45.0 : 135.0
        let fraction = min(1, max(0, progress))
        guard fraction > 0 else { return path }
        path.addArc(center: center, radius: scale * radius, startAngle: start * .pi / 180,
                    endAngle: (start + 270 * fraction) * .pi / 180, clockwise: false)
        return path
    }
}
