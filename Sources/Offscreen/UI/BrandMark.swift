import SwiftUI

struct BrandMark: View {
    var body: some View {
        GeometryReader { proxy in
            Path(BrandGeometry.path(in: CGRect(origin: .zero, size: proxy.size)))
                .stroke(style: StrokeStyle(lineWidth: min(proxy.size.width, proxy.size.height) * 0.075, lineCap: .round))
        }.accessibilityHidden(true)
    }
}

/// Work/rest progress outside, completed short breaks inside.
struct TimerRing: View {
    let progress: RingProgress
    var color: Color
    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            let stroke = StrokeStyle(lineWidth: min(proxy.size.width, proxy.size.height) * 0.065, lineCap: .round)
            Path(BrandGeometry.ring(in: rect, outer: true))
                .stroke(Color.secondary.opacity(0.18), style: stroke)
            Path(BrandGeometry.ring(in: rect, outer: true, progress: progress.outer))
                .stroke(color, style: stroke)
            if let inner = progress.inner {
                Path(BrandGeometry.ring(in: rect, outer: false))
                    .stroke(Color.secondary.opacity(0.18), style: stroke)
                Path(BrandGeometry.ring(in: rect, outer: false, progress: inner))
                    .stroke(color, style: stroke)
            }
        }.accessibilityHidden(true)
    }
}
