import SwiftUI

struct DashboardView: View {
    let model: AppContainer

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Molaway").font(.system(size: 25, weight: .semibold, design: .rounded))
                Spacer()
                BrandMark().frame(width: 32, height: 32).foregroundStyle(model.tint)
            }
            Label(model.statusText, systemImage: statusSymbol)
                .font(.caption).foregroundStyle(.secondary).lineLimit(2)

            VStack(spacing: 12) {
                ZStack {
                    TimerRing(progress: model.ringProgress, color: model.tint)
                        .frame(width: 184, height: 184)
                    VStack(spacing: 2) {
                        Text(model.nextReadout.resting ? L("Rest time") : L(model.nextReadout.deferred ? "Next reminder" : "Next break"))
                            .font(.caption2).foregroundStyle(.secondary)
                        Text(model.nextReadout.kind.title)
                            .font(.caption2.weight(.medium))
                        Text(model.nextReadout.clock)
                            .font(.system(size: 23, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                    .multilineTextAlignment(.center)
                    .frame(width: 78)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel((model.nextReadout.resting ? L("Rest time") : L(model.nextReadout.deferred ? "Next reminder" : "Next break")) + ": " + model.nextReadout.kind.title + ", " + model.nextReadout.clock)

                VStack(alignment: .leading, spacing: 5) {
                    Label(L("Outer ring") + " · " + L(model.activeRest == nil ? "Work progress" : "Rest progress")
                          + ": \(Int((model.ringProgress.outer * 100).rounded()))%", systemImage: "circle.dotted")
                    if model.config.shortBreaksBeforeLong > 0 {
                        Label(L("Inner ring") + " · " + String(format: L("%d of %d short breaks completed"),
                             min(model.breakEngine.shortBreaksSinceLong, model.config.shortBreaksBeforeLong), model.config.shortBreaksBeforeLong),
                              systemImage: "circle.circle")
                    } else {
                        Label(L("Inner ring") + " · " + L("Long breaks off"), systemImage: "circle.slash")
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)

            if model.visibleOverdue != .normal {
                Label(L("A break is overdue"), systemImage: "exclamationmark.circle")
                    .font(.caption).foregroundStyle(model.visibleOverdue == .red ? .red : Theme.amber)
            }
            if model.hasAlertProblem {
                Button { model.openAlertSettings() } label: {
                    Label(L("Review notification settings"), systemImage: "exclamationmark.triangle")
                }.buttonStyle(.bordered).controlSize(.small)
            }

            if model.activeRest != nil {
                Button(L("End break and continue")) { model.cancelRest() }
                    .buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
            } else {
                HStack {
                    Button { model.beginRest(model.nextKind) } label: {
                        Label(L("Take a break"), systemImage: "leaf")
                    }.buttonStyle(.borderedProminent)
                    Spacer()
                    Menu {
                        Button(L("Long break now")) { model.beginRest(.long) }
                        if !model.isWatching { Button(L("Watching mode")) { model.toggleWatching() } }
                        if model.presentationUntil == nil { Button(L("Presentation")) { model.togglePresentation() } }
                    } label: {
                        Label(L("More actions"), systemImage: "ellipsis.circle")
                    }.menuStyle(.borderlessButton)
                }
            }

            if model.isWatching || model.presentationUntil != nil {
                HStack {
                    if model.isWatching {
                        Button(L("End watching")) { model.toggleWatching() }
                    }
                    if model.presentationUntil != nil {
                        Button(L("End presentation")) { model.togglePresentation() }
                    }
                }.buttonStyle(.bordered).controlSize(.small)
            }

            Divider()
            HStack {
                PauseControls(model: model)
                Spacer()
                Button { model.openSettingsAction?() } label: {
                    Label(L("Settings"), systemImage: "gearshape")
                }
            }.buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .padding(20).frame(width: 342)
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
