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
                VStack(spacing: 12) {
                    TimerRing(progress: model.ringProgress, color: model.tint)
                        .frame(width: 144, height: 144)
                    VStack(spacing: 3) {
                        Text(model.nextReadout.resting ? L("Rest time") : L(model.nextReadout.deferred ? "Next reminder" : "Next break"))
                            .font(.caption).foregroundStyle(.secondary)
                        Text(model.nextReadout.kind.title)
                            .font(.callout.weight(.medium))
                        Text(model.nextReadout.clock)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
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
                skipControl
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
                if !model.reminderKinds.isEmpty && !model.isPreview { skipControl }
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

            if model.config.officeHours.enabled {
                VStack(alignment: .leading, spacing: 4) {
                    Button { model.openOfficeHours() } label: {
                        Label(model.officeHoursText, systemImage: "calendar.badge.clock")
                    }.buttonStyle(.plain)
                    if let next = model.nextOfficeStartText { Text(next).foregroundStyle(.secondary) }
                }.font(.caption).fixedSize(horizontal: false, vertical: true)
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

    @ViewBuilder private var skipControl: some View {
        if model.config.skipMode != .hardcore {
            Button(model.skipCountdown.map { $0 > 0 ? String(format: L("Skip in %d s"), $0) : L("Skip break") } ?? L("Skip break")) {
                model.skipBreak()
            }
            .buttonStyle(.bordered)
            .disabled(!model.canSkipBreak)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(model.skipCountdown.map { $0 > 0 ? String(format: L("Skip available in %d seconds"), $0) : L("Skip break") } ?? L("Skip break"))
        }
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
