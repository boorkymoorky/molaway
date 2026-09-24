import SwiftUI

struct AlertSurfaceModifier: ViewModifier {
    let surface: AlertSurface
    let density: Double
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    func body(content: Content) -> some View {
        if surface == .solid || reduceTransparency || contrast == .increased {
            content.background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 22))
        } else if #available(macOS 26.0, *) {
            content.glassEffect(.regular.tint(Color(nsColor: .windowBackgroundColor).opacity(density)), in: .rect(cornerRadius: 22))
        } else {
            content.background(Color(nsColor: .windowBackgroundColor).opacity(density * 0.8), in: RoundedRectangle(cornerRadius: 22))
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        }
    }
}
