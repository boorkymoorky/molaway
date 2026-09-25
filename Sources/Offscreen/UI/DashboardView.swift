import SwiftUI

struct DashboardView: View {
    let model: AppContainer
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Molaway").font(.system(size: 25, weight: .semibold, design: .rounded))
                    Text(L("Small breaks, a better day.")).font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                BrandMark().frame(width: 34, height: 34).foregroundStyle(model.tint)
            }
            Label(model.statusText, systemImage: statusSymbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Label {
                Text(L(model.nextReadout.resting ? "Rest time" : "Next reminder") + ": " + model.nextReadout.kind.title + " · " + model.nextReadout.clock)
                    .monospacedDigit()
            } icon: { Image(systemName: model.nextReadout.kind.symbol) }
            .font(.system(size: 11, weight: .medium)).foregroundStyle(model.tint)
            .fixedSize(horizontal: false, vertical: true)
            if model.visibleOverdue != .normal {
                Label(L("A break is overdue"), systemImage: "exclamationmark.circle").font(.caption).foregroundStyle(model.visibleOverdue == .red ? .red : Theme.amber)
            }
            if model.hasAlertProblem {
                Button { model.openAlertSettings() } label: {
                    Label(L("Review notification settings"), systemImage: "exclamationmark.triangle")
                }.buttonStyle(.bordered).controlSize(.small)
            }
            VStack(spacing: 10) {
                TimerCard(model: model, kind: .eyes)
                TimerCard(model: model, kind: .movement)
            }
            if model.activeRest != nil {
                Button(L("End break and continue")) { model.cancelRest() }
                    .buttonStyle(.bordered).frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 8) {
                    Button { model.beginRest(.eyes) } label: { Label(L("Eye break"), systemImage: "eye") }
                    Button { model.beginRest(.movement) } label: { Label(L("Move"), systemImage: "figure.walk") }
                }.buttonStyle(.bordered).controlSize(.regular)
            }
            HStack {
                Button(L(model.isWatching ? "End watching" : "Watching mode")) { model.toggleWatching() }
                Button(L(model.presentationUntil == nil ? "Presentation" : "End presentation")) { model.togglePresentation() }
            }.buttonStyle(.bordered).controlSize(.small)
            if let until = model.watchingUntil {
                HStack {
                    Label(L("Watching mode"), systemImage: "play.rectangle")
                    Spacer()
                    Text(until, style: .timer).monospacedDigit()
                    Button(L("Extend")) { model.extendWatching() }.buttonStyle(.bordered)
                }.font(.caption).controlSize(.small)
            }
            if let until = model.presentationUntil {
                HStack {
                    Label(L("Presentation mode"), systemImage: "bell.slash")
                    Spacer()
                    Text(until, style: .timer).monospacedDigit()
                }.font(.caption)
            }
            Button { model.openStatistics() } label: { Label(L("Your overview"), systemImage: "chart.bar.xaxis") }.buttonStyle(.plain).font(.caption).foregroundStyle(model.tint)
            Divider()
            HStack {
                Button(model.isPaused ? L("Resume tracking") : L("Pause 30 min")) { model.togglePause() }
                    .buttonStyle(.plain).font(.system(size: 12))
                Spacer()
                Button { model.openSettingsAction?() } label: { Image(systemName: "gearshape") }
                    .buttonStyle(.plain).help(L("Settings")).accessibilityLabel(L("Settings"))
                Button { NSApplication.shared.terminate(nil) } label: { Image(systemName: "power") }
                    .buttonStyle(.plain).help(L("Quit Molaway")).accessibilityLabel(L("Quit Molaway"))
            }.foregroundStyle(.secondary)
        }
        .padding(22).frame(width: 342)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    private var statusSymbol: String {
        switch model.activity {
        case .video: "play.rectangle"
        case .away, .sleeping, .paused: "pause.circle"
        case .resting: "leaf"
        default: "circle.dotted"
        }
    }
}

struct TimerCard: View {
    let model: AppContainer
    let kind: MolaKind
    private var engine: BreakEngine { model.engine(kind) }
    private var color: Color { kind == .eyes ? model.tint : Theme.violet }
    private var readout: AppContainer.TimerReadout { model.readout(for: kind) }
    private var inRest: Bool { readout.resting }
    private var progress: Double {
        inRest ? 1 - engine.breakProgress : min(1, max(0, engine.workAccrued / Double(engine.timing.workSeconds)))
    }
    var body: some View {
        HStack(spacing: 15) {
            TimerRing(kind: kind, progress: progress, color: color).frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 3) {
                Label(kind.title, systemImage: kind.symbol).font(.system(size: 13, weight: .semibold))
                Text(L(kind == .eyes ? "Outer ring" : "Inner ring")).font(.system(size: 10)).foregroundStyle(color)
                Text(inRest ? L("Rest time") : L("Every") + " " + minutes(engine.timing.workSeconds / 60))
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 2)
            VStack(alignment: .trailing, spacing: 3) {
                Text(readout.clock)
                    .font(.system(size: 20, weight: .medium, design: .rounded)).monospacedDigit()
                    .foregroundStyle(engine.timeUntilBreak <= 0 && !inRest ? Theme.amber : .primary)
                Text(inRest ? L("left") : L(readout.deferred ? "until reminder" : "until break")).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }.padding(15)
            .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.1)))
            .accessibilityElement(children: .combine)
    }
}
