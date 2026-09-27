import AppKit
import SwiftUI

struct PreBreakView: View {
    let model: AppContainer
    let style: ReminderStyle
    let availableSize: CGSize
    var onHover: (Bool) -> Void = { _ in }
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    private var kind: MolaKind { model.activeRest ?? model.nextKind }
    private var full: Bool { style == .fullScreen }
    var body: some View {
        ZStack {
            if full { Color.black.opacity(reduceTransparency ? 1 : model.config.fullScreenDim).ignoresSafeArea() }
            ScrollView { VStack(alignment: .leading, spacing: full ? 26 : 18) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: !model.isPreview && model.activeRest == nil && model.visibleOverdue == .red ? "exclamationmark.circle" : kind.symbol).font(.system(size: full ? 44 : 26)).foregroundStyle(model.tint)
                        .frame(width: full ? 76 : 48, height: full ? 76 : 48)
                        .background(model.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
                    VStack(alignment: .leading, spacing: 8) {
                        Text(model.isPreview ? L("Alert preview") : kind.title)
                            .font(.system(size: full ? 30 : 17, weight: .semibold, design: .rounded))
                        Text(model.reminderMessage(kind)).font(.system(size: full ? 19 : 13)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Button { model.dismissReminder() } label: { Image(systemName: "xmark").frame(width: 24, height: 24) }
                        .buttonStyle(.plain).accessibilityLabel(L("Close alert")).keyboardShortcut(.cancelAction)
                }
                if model.isPreview {
                    HStack { Text(L("Your timers are unchanged.")).font(.caption).foregroundStyle(.secondary); Spacer(); Button(L("Close preview")) { model.dismissReminder() }.keyboardShortcut(.cancelAction) }
                } else if model.activeRest != nil {
                    HStack(alignment: .center) {
                        Text(Format.clock(model.engine(kind).breakRemaining)).font(.system(size: full ? 64 : 30, weight: .medium, design: .rounded)).monospacedDigit()
                        Spacer()
                        skipControl
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button(L("Take a break")) { model.beginRest(kind) }.buttonStyle(.borderedProminent).tint(model.tint)
                            Button(L("Snooze 5 min")) { model.snoozeReminder() }.buttonStyle(.bordered)
                            Spacer()
                        }
                        HStack {
                            skipControl
                            Spacer()
                            Text("\(BreakScheduleMath.duration(of: kind == .long ? .long : .short, timing: model.breakEngine.timing)) " + L("sec")).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                if full {
                    HStack {
                        Text(L("Esc to close · your timers keep running")).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button(L("Quit Molaway")) { NSApp.terminate(nil) }.buttonStyle(.plain).font(.caption)
                    }
                }
            }
            .padding(full ? 36 : 22)
            }.scrollBounceBehavior(.basedOnSize)
            .frame(width: min(full ? 640 : style == .banner ? 520 : 390, max(160, availableSize.width - 32)))
            .frame(maxHeight: max(100, availableSize.height - 32))
            .fixedSize(horizontal: false, vertical: true)
            .modifier(AlertSurfaceModifier(surface: model.config.alertSurface, density: model.config.surfaceDensity))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(model.tint.opacity(0.15)))
            .onHover(perform: onHover)
        }.frame(maxWidth: full ? .infinity : nil, maxHeight: full ? .infinity : nil)
    }
    @ViewBuilder private var skipControl: some View {
        if model.config.skipMode != .hardcore {
            Button(model.skipCountdown.map { $0 > 0 ? String(format: L("Skip in %d s"), $0) : L("Skip break") } ?? L("Skip break")) {
                model.skipBreak()
            }
            .buttonStyle(.bordered)
            .disabled(!model.canSkipBreak)
            .accessibilityLabel(model.skipCountdown.map { $0 > 0 ? String(format: L("Skip available in %d seconds"), $0) : L("Skip break") } ?? L("Skip break"))
        }
    }
}
