import SwiftUI

struct BrandMark: View {
    var body: some View {
        GeometryReader { proxy in
            Path(BrandGeometry.path(in: CGRect(origin: .zero, size: proxy.size)))
                .stroke(style: StrokeStyle(lineWidth: min(proxy.size.width, proxy.size.height) * 0.075, lineCap: .round))
        }.accessibilityHidden(true)
    }
}

/// The same two rings as the menu icon; the relevant ring carries progress.
struct TimerRing: View {
    let kind: MolaKind
    var progress: Double = 1
    var color: Color
    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            let stroke = StrokeStyle(lineWidth: min(proxy.size.width, proxy.size.height) * 0.075, lineCap: .round)
            Path(BrandGeometry.ring(in: rect, outer: kind != .eyes))
                .stroke(Color.secondary.opacity(0.18), style: stroke)
            Path(BrandGeometry.ring(in: rect, outer: kind == .eyes))
                .stroke(color.opacity(0.22), style: stroke)
            Path(BrandGeometry.ring(in: rect, outer: kind == .eyes, progress: progress))
                .stroke(color, style: stroke)
        }.accessibilityHidden(true)
    }
}
