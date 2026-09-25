import SwiftUI
import Charts

struct StatisticsView: View {
    let model: AppContainer
    @State private var period = 7
    @State private var metric = 0
    @State private var selectedDay: String?
    @State private var disableDialog = false
    @State private var deleteDialog = false
    @State private var retentionDialog = false
    private var stats: StatisticsStore { model.statistics }
    private var today: String { StatsCalendar.key(Date()) }
    @State private var snapshots: [Int: StatisticsSnapshot] = [:]
    private struct Input: Equatable {
        var days: [DailySummary]; var today: String; var language: String
    }
    private var input: Input { Input(days: stats.days, today: today, language: Localization.shared.code) }
    private var snapshot: StatisticsSnapshot? { snapshots[period] }
    private var keys: [String] { snapshot?.keys ?? [] }
    private var rows: [DailySummary] { snapshot?.rows ?? [] }
    private var total: DailySummary { snapshot?.totals ?? DailySummary(day: today) }
    private var selectedRow: DailySummary? { selectedDay.flatMap { snapshot?.byDay[$0] } }
    private var comparison: StatisticsComparison? { snapshot?.comparison }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(L("Save daily summaries on this Mac"), isOn: Binding(get: { stats.enabled }, set: {
                        if $0 { model.setStatisticsEnabled(true) } else { disableDialog = true }
                    })).disabled(stats.failed)
                    Text(L("Optional, off by default. Only daily totals, never apps, websites or input. No new permission or network access.")).font(.caption).foregroundStyle(.secondary)
                    if stats.failed {
                        Label(L("Statistics could not be read or saved. Recording has stopped. Clear the data to start again."), systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.red)
                    } else if !stats.enabled && !stats.days.isEmpty {
                        Label(L("Recording is off. Previously saved summaries remain on this Mac."), systemImage: "pause.circle").font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(16).background(model.tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                if stats.days.isEmpty {
                    VStack(spacing: 14) {
                        BrandMark().frame(width: 64, height: 64).foregroundStyle(model.tint)
                        Text(L(stats.enabled ? "Your day will take shape here" : "A little perspective, only if you want it")).font(.title3.weight(.semibold))
                        Text(L("Enable summaries to see your active time and completed breaks. No past activity is reconstructed.")).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, 30)
                } else {
                    Picker(L("Period"), selection: $period) {
                        Text(L("Week")).tag(7); Text(L("Month")).tag(30); Text(L("90 days")).tag(90)
                    }.pickerStyle(.segmented).onChange(of: period) { _, _ in selectedDay = nil }
                    Text(String(format: L("%d days with data · today is still in progress"), rows.count)).font(.caption).foregroundStyle(.secondary)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) { cards }
                        VStack(spacing: 10) { cards }
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        Picker(L("Chart"), selection: $metric) {
                            Text(L("Active time")).tag(0); Text(L("Breaks")).tag(1); Text(L("Rest time")).tag(2)
                        }.pickerStyle(.segmented)
                        chart.frame(height: 200)
                        HStack {
                            Image(systemName: "xmark"); Text(L("No data is different from zero use."))
                        }.font(.caption2).foregroundStyle(.secondary)
                        if let key = selectedDay {
                            Text(dayLabel(key) + " · " + (selectedRow.map { metric == 1 ? String($0.breaks) + " " + L("breaks completed") : duration(metric == 0 ? $0.active : $0.rest) } ?? L("No data")))
                                .font(.caption).accessibilityAddTraits(.updatesFrequently)
                        }
                        if let comparison {
                            let p = comparison.percent
                            Label(String(format: L("%@%d%% active time per recorded day"), p >= 0 ? "+" : "", p), systemImage: p >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.subheadline.weight(.medium))
                            Text(String(format: L("Last %d completed days vs the preceding %d; %d and %d days with data. Today is excluded."), period, period, comparison.currentDays, comparison.previousDays))
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text(L("Comparisons appear when both periods have enough recorded days. Missing days are not treated as zero.")).font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(16).background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                    DisclosureGroup(L("Break and video details")) {
                        VStack(spacing: 10) {
                            detail("Eye breaks completed", String(total.eyes))
                            detail("Movement breaks completed", String(total.movement))
                            detail("Natural breaks included", String(total.natural))
                            detail("Detected video · estimated", duration(total.video))
                            detail("Manual watching · no video signal", duration(total.watching))
                            Text(L("One break may meet both targets, but counts once in the total. Natural breaks use the qualifying duration, not all time away. Video and watching are parts of active time; playback cannot prove you are at your desk.")).font(.caption).foregroundStyle(.secondary)
                        }.padding(.top, 12)
                    }
                    Text(L("Daily totals update about every 15 seconds. Unconfirmed idle time is not saved; the last minute may be lost after a crash. These are estimates, not health measurements.")).font(.caption).foregroundStyle(.secondary)
                }
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    Picker(L("Keep summaries for"), selection: Binding(get: { stats.retention }, set: {
                        if $0 < stats.retention { retentionDialog = true } else { stats.setRetention($0) }
                    })) { Text(L("30 days")).tag(30); Text(L("90 days")).tag(90) }.disabled(stats.failed)
                    Toggle(L("Optional weekly summary notification"), isOn: Binding(get: { stats.weekly }, set: { model.setWeeklySummary($0) })).disabled(!stats.enabled || stats.failed)
                    Text(L("Permission: macOS notifications. At most once a week with enough data; no figures on the lock screen. Quiet modes are respected. No trend-change alerts.")).font(.caption).foregroundStyle(.secondary)
                    if stats.weekly && model.notifications?.authorization != .authorized {
                        Button(L("Review notification settings")) { model.openAlertSettings() }
                    }
                    Button(L("Delete summaries and turn recording off"), role: .destructive) { deleteDialog = true }
                        .disabled(stats.days.isEmpty && !stats.enabled && !stats.failed)
                    Text(L("Statistics are separate from settings backups. Turning recording off lets you keep or delete previous data.")).font(.caption).foregroundStyle(.secondary)
                }
            }.padding(24)
        }
        .onChange(of: input, initial: true) { _, value in
            snapshots = Dictionary(uniqueKeysWithValues: [7, 30, 90].map { period in
                (period, StatisticsSnapshot(days: value.days, period: period, today: value.today, language: value.language))
            })
        }
        .confirmationDialog(L("Stop recording summaries?"), isPresented: $disableDialog, titleVisibility: .visible) {
            Button(L("Stop and keep existing data")) { model.setStatisticsEnabled(false) }
            Button(L("Stop and delete data"), role: .destructive) { model.clearStatistics() }
            Button(L("Cancel"), role: .cancel) {}
        }
        .confirmationDialog(L("Delete all summaries? This cannot be undone."), isPresented: $deleteDialog, titleVisibility: .visible) {
            Button(L("Delete summaries and turn recording off"), role: .destructive) { model.clearStatistics() }
            Button(L("Cancel"), role: .cancel) {}
        }
        .confirmationDialog(L("Keep only 30 days? Older summaries will be deleted."), isPresented: $retentionDialog, titleVisibility: .visible) {
            Button(L("Keep 30 days"), role: .destructive) { stats.setRetention(30) }
            Button(L("Cancel"), role: .cancel) {}
        }
    }
    @ViewBuilder private var cards: some View {
        card("Active time", value: duration(total.active), symbol: "desktopcomputer")
        card("Breaks completed", value: String(total.breaks), symbol: "checkmark.circle")
        card("Rest time", value: duration(total.rest), symbol: "leaf")
    }
    private func card(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).foregroundStyle(model.tint)
            Text(value).font(.system(size: 22, weight: .semibold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
            Text(L(title)).font(.caption).foregroundStyle(.secondary)
        }.frame(minWidth: 100, maxWidth: .infinity, alignment: .leading).padding(14)
            .background(model.tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            .accessibilityElement(children: .combine)
    }
    private var chart: some View {
        Chart {
            ForEach(keys, id: \.self) { key in
                if let row = snapshot?.byDay[key] {
                    BarMark(x: .value(L("Day"), key), y: .value(unit, chartValue(row)))
                        .foregroundStyle(model.tint.gradient).cornerRadius(3)
                        .accessibilityLabel(dayLabel(key)).accessibilityValue(metric == 1 ? String(row.breaks) : duration(metric == 0 ? row.active : row.rest))
                } else {
                    PointMark(x: .value(L("Day"), key), y: .value(unit, 0))
                        .symbol(.cross).symbolSize(12).foregroundStyle(Color.secondary.opacity(0.4))
                        .accessibilityLabel(dayLabel(key) + ": " + L("No data"))
                }
            }
            if let selectedDay {
                RuleMark(x: .value(L("Day"), selectedDay)).foregroundStyle(.secondary.opacity(0.3))
            }
        }
        .chartXScale(range: .plotDimension(padding: 20))
        .chartXSelection(value: $selectedDay)
        .chartXAxis {
            AxisMarks(values: snapshot?.axisKeys ?? []) { value in
                AxisValueLabel { if let key = value.as(String.self) { Text(dayLabel(key)).font(.caption2) } }
            }
        }
        .chartYAxisLabel(unit)
    }
    private var unit: String { L(metric == 0 ? "hours" : metric == 1 ? "breaks" : "minutes") }
    private func chartValue(_ row: DailySummary) -> Double { metric == 0 ? row.active / 3600 : metric == 1 ? Double(row.breaks) : row.rest / 60 }
    private func duration(_ value: Double) -> String {
        let seconds = Int(max(0, value))
        if seconds < 60 { return "\(seconds) " + L("sec") }
        let minutes = seconds / 60
        return minutes >= 60 ? "\(minutes / 60) " + L("h") + " \(minutes % 60) " + L("min") : "\(minutes) " + L("min")
    }
    private func dayLabel(_ key: String) -> String {
        snapshot?.labels[key] ?? key
    }
    private func detail(_ title: String, _ value: String) -> some View { HStack { Text(L(title)); Spacer(); Text(value).monospacedDigit() }.font(.caption) }
}
