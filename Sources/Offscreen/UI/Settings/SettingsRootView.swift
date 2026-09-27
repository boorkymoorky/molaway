import SwiftUI
import Intents
import UserNotifications

struct SettingsRootView: View {
    let model: AppContainer
    @State private var hoveredTab: Int?
    @State private var license = false
    private let tabs = ["Breaks", "Activity", "Alerts", "Appearance & sound", "Privacy & permissions", "Overview"]
    private let symbols = ["eye", "timer", "rectangle.topthird.inset.filled", "paintpalette", "lock.shield", "chart.bar.xaxis"]
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 7) {
                Label { Text("Molaway") } icon: { BrandMark().frame(width: 30, height: 30) }.font(.system(size: 27, weight: .semibold, design: .rounded)).foregroundStyle(model.tint).padding(.vertical, 24)
                ForEach(tabs.indices, id: \.self) { index in
                    Button { model.settingsTab = index; model.notifications?.refresh() } label: {
                        Label(L(tabs[index]), systemImage: symbols[index]).font(.system(size: 12, weight: model.settingsTab == index ? .semibold : .regular))
                            .frame(maxWidth: .infinity, alignment: .leading).padding(11)
                            .background(model.settingsTab == index ? model.tint.opacity(0.12) : hoveredTab == index ? model.tint.opacity(0.06) : .clear, in: RoundedRectangle(cornerRadius: 10))
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain).foregroundStyle(model.settingsTab == index ? model.tint : .primary)
                        .onHover { hoveredTab = $0 ? index : nil }
                        .accessibilityAddTraits(model.settingsTab == index ? [.isSelected] : [])
                }
                Spacer()
                Label(L("Only on this Mac"), systemImage: "lock").font(.caption).foregroundStyle(.secondary)
                Text("Molaway \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—") · MIT").font(.caption2).foregroundStyle(.secondary)
            }.padding(18).frame(width: 200).background(model.tint.opacity(0.04))
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                Text(L(tabs[model.settingsTab])).font(.system(size: 25, weight: .semibold, design: .rounded)).padding(24)
                Group {
                    switch model.settingsTab { case 0: breaks; case 1: activity; case 2: alerts; case 3: appearance; case 5: StatisticsView(model: model); default: privacy }
                }.formStyle(.grouped).scrollContentBackground(.hidden)
                if let feedback = model.feedback {
                    HStack { Text(feedback).font(.caption); Spacer(); Button(L("Dismiss")) { model.feedback = nil } }.padding(.horizontal, 20).padding(.vertical, 8)
                }
                HStack {
                    Circle().fill(model.tint).frame(width: 6, height: 6)
                    Text(model.statusText).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    Spacer()
                    Button(L("Show timers")) { model.openDashboardAction?() }.buttonStyle(.plain).foregroundStyle(model.tint)
                }.padding(18)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(nsColor: .windowBackgroundColor))
            .sheet(isPresented: $license) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L("License & credits")).font(.title2.bold())
                    ScrollView { Text(licenseText).font(.system(size: 11, design: .monospaced)).textSelection(.enabled) }
                    Button(L("Close")) { license = false }.keyboardShortcut(.cancelAction)
                }.padding(24).frame(width: 620, height: 440)
            }
    }
    private var breaks: some View {
        Form {
            Section(L("Timing profile")) {
                HStack {
                    Button(L("Balanced")) { model.settings.update { $0.applyPreset(.balanced) } }
                    Button(L("Deep Focus")) { model.settings.update { $0.applyPreset(.deepFocus) } }
                    Button(L("20-20-20")) { model.settings.update { $0.applyPreset(.twentyTwentyTwenty) } }
                }
                if model.config.previousCustomTiming != nil {
                    Button(L("Restore previous timing")) { model.settings.update { $0.restorePreviousTiming() } }
                }
            }
            Section(L("Break cycle")) {
                DurationField(title: "Work interval", value: model.settings.binding(\.workMinutes), range: 5...180, unit: "min", step: 5)
                DurationField(title: "Short break duration", value: model.settings.binding(\.shortRestSeconds), range: 10...120, unit: "sec", step: 10)
                DurationField(title: "Long break duration", value: model.settings.binding(\.longRestMinutes), range: 1...15, unit: "min")
                Picker(L("Short breaks before long"), selection: model.settings.binding(\.shortBreaksBeforeLong)) {
                    Text(L("Long breaks off")).tag(0)
                    ForEach(1...12, id: \.self) { value in Text(String(value)).tag(value) }
                }
                if model.config.shortBreaksBeforeLong > 0 {
                    Text(String(format: L("%d completed short breaks are followed by one long break. Skips and snoozes do not advance the count."), model.config.shortBreaksBeforeLong))
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                } else { note("Only short breaks are scheduled. Skips and snoozes do not advance the count.") }
                note("Changes to rest duration apply to your next break.")
            }
            if model.config.migrationNoticePending {
                Section(L("Your break schedule changed")) {
                    Text(L("Your former eye interval became the work interval; eye rest became the short break; movement rest became the long break. The independent movement interval has no exact match. Review the new schedule below; old eye and movement statistics retain their original meaning."))
                    Button(L("I reviewed the schedule")) { model.settings.update { $0.migrationNoticePending = false } }
                }
            }
            Section(L("Settings backup")) {
                HStack { Button(L("Export settings")) { SettingsTransfer.export(model) }; Button(L("Import settings")) { SettingsTransfer.importSettings(model) } }
                note("Permission: only the file you choose. No activity history is exported. Import does not grant permissions.")
            }
        }
    }
    private var activity: some View {
        Form {
            Section(L("Automatic tracking")) {
                Picker(L("Pause after inactivity"), selection: model.settings.binding(\.idlePauseSeconds)) {
                    ForEach([30, 60, 120, 180, 300, 600], id: \.self) { seconds in Text(seconds < 60 ? "30 " + L("sec") : minutes(seconds / 60)).tag(seconds) }
                }
                note("Permission: none. Only time since mouse/keyboard activity is read, never keys or text.")
                Toggle(L("Keep counting during video"), isOn: model.settings.binding(\.videoEnabled))
                note("Permission: none. Uses video power signals, not screen contents. Some players or small videos may not report a signal.")
                if model.config.videoEnabled { status(model.videoAvailable ? model.videoPlaying ? "Video detected" : "No video signal" : "Video status unavailable") }
            }
            Section(L("Watching mode")) {
                HStack {
                    ForEach([15, 30, 60, 120], id: \.self) { value in
                        Button(minutes(value)) { model.settings.update { $0.watchingMinutes = value } }
                    }
                }.controlSize(.small)
                DurationField(title: "Duration", value: model.settings.binding(\.watchingMinutes), range: 5...240, unit: "min", step: 5)
                HStack {
                    Button(L(model.isWatching ? "End watching mode" : "Start watching mode")) { model.toggleWatching() }
                    if model.isWatching { Button(L("Extend")) { model.extendWatching() } }
                }
                if let until = model.watchingUntil { Text(L("Ends at") + " " + until.formatted(date: .omitted, time: .shortened)).font(.caption) }
                note("Keeps counting without mouse input. Lock the screen when leaving a playing video.")
            }
            Section(L("Quiet during meetings")) {
                Toggle(L("When a camera is in use"), isOn: model.settings.binding(\.cameraSuppression))
                note("Permission: no camera recording access requested. Reads device running state only; some devices may be unavailable.")
                if model.config.cameraSuppression { status(model.cameraActive == nil ? "Camera status unavailable" : model.cameraActive == true ? "Camera in use" : "Camera idle") }
                Toggle(L("Respect shared Focus status"), isOn: Binding(get: { model.config.focusSuppression }, set: { enabled in model.settings.update { $0.focusSuppression = enabled }; if enabled { model.requestFocus() } }))
                note("Permission: Focus status sharing. Availability depends on macOS and app capabilities. Use Presentation mode if unavailable; native notifications follow macOS Focus rules.")
                if model.config.focusSuppression { status(model.focusActive == nil ? "Focus status unavailable" : model.focusActive == true ? "Focus active" : "Focus allows alerts") }
            }
            Section(L("Presentation mode")) {
                DurationField(title: "Duration", value: model.settings.binding(\.presentationMinutes), range: 5...240, unit: "min", step: 5)
                Button(L(model.presentationUntil == nil ? "Start presentation mode" : "End presentation mode")) { model.togglePresentation() }
                if let until = model.presentationUntil { Text(L("Ends at") + " " + until.formatted(date: .omitted, time: .shortened)).font(.caption) }
                note("Permission: none. Quiet alerts and sounds while timers follow normal activity rules. After quiet mode, wait 60 seconds before one combined reminder.")
            }
        }
    }
    private var alerts: some View {
        Form {
            Section(L("Alert style")) {
                Picker(L("Style"), selection: model.settings.binding(\.reminderStyle)) { ForEach(ReminderStyle.allCases, id: \.self) { Text($0.title).tag($0) } }
                note(model.config.reminderStyle == .notification ? "Permission: Notifications. macOS controls placement, Focus, sound level and delivery. Other styles need no notification permission." : "Permission: none. Custom windows do not read your screen. Full screen stays in the current Space; Esc and the close button remain available.")
                if model.config.reminderStyle == .notification { notificationPermission }
                Picker(L("Show on"), selection: model.settings.binding(\.displayTarget)) { ForEach(DisplayTarget.allCases, id: \.self) { Text($0.title).tag($0) } }.disabled(model.config.reminderStyle == .notification)
                DurationField(title: "Alert duration", value: model.settings.binding(\.reminderVisibleSeconds), range: 5...30, unit: "sec").disabled(model.config.reminderStyle == .notification)
                note("A reminder is not a completed break. Closing it keeps tracking. Snooze silences both break reminders for at least 5 active minutes.")
                if model.config.reminderStyle != .notification {
                    Picker(L("Panel surface"), selection: model.settings.binding(\.alertSurface)) {
                        ForEach(AlertSurface.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    if model.config.alertSurface != .solid {
                        PercentageSlider(title: "Background opacity", value: model.settings.binding(\.surfaceDensity), range: 0.3...1)
                    }
                    if model.config.reminderStyle == .fullScreen {
                        PercentageSlider(title: "Full screen dimming", value: model.settings.binding(\.fullScreenDim), range: 0.4...1)
                    }
                    note("Text stays readable. Reduce Transparency and Reduce Motion take priority. Native notifications follow macOS appearance.")
                    Button(L("Reset alert appearance")) { model.settings.update { $0.alertSurface = .system; $0.surfaceDensity = 0.65; $0.fullScreenDim = 0.85 } }
                }
                Button(L("Preview alert & sound")) { model.previewReminder() }
            }
            Section(L("Overdue reminders")) {
                Toggle(L("Make overdue breaks more noticeable"), isOn: model.settings.binding(\.overdueEnabled))
                DurationField(title: "Amber after", value: model.settings.binding(\.amberMinutes), range: 5...60, unit: "min", step: 5).disabled(!model.config.overdueEnabled)
                DurationField(title: "Red after", value: model.settings.binding(\.redMinutes), range: (model.config.amberMinutes + 5)...120, unit: "min", step: 5).disabled(!model.config.overdueEnabled)
                note("Uses active time after a break is due. Red also requires 3 deliberate snoozes. No flashing or extra alerts; quiet modes take priority.")
            }
            Section(L("Menu bar & startup")) {
                Toggle(L("Show remaining time in menu bar"), isOn: model.settings.binding(\.showCountdownInMenuBar))
                Toggle(L("Launch at login"), isOn: Binding(get: { model.loginEnabled }, set: { model.setLogin($0) }))
                note("Permission: macOS login-item approval may be required. No administrator access.")
                if let error = model.loginError { Text(error).font(.caption).foregroundStyle(.red) }
            }
        }
    }
    private var appearance: some View {
        Form {
            Section(L("Language & theme")) {
                Picker(L("Language"), selection: model.settings.binding(\.language)) { ForEach(AppLanguage.allCases, id: \.self) { Text($0.title).tag($0) } }
                Picker(L("Appearance"), selection: model.settings.binding(\.appearance)) { ForEach(AppAppearance.allCases, id: \.self) { Text($0.title).tag($0) } }
                Picker(L("Accent"), selection: model.settings.binding(\.accent)) { ForEach(Accent.allCases, id: \.self) { Text($0.title).tag($0) } }
                note("Follows Reduce Motion and uses readable system text. Unsupported system languages use English.")
            }
            Section(L("Sounds")) {
                soundRow("Reminder", \.reminderTone)
                soundRow("App starts", \.startTone)
                soundRow("Tracking pauses", \.pauseTone)
                soundRow("Tracking resumes", \.resumeTone)
                soundRow("Break starts", \.breakTone)
                soundRow("Break ends", \.endTone)
                PercentageSlider(title: "App sound volume", value: model.settings.binding(\.soundVolume), range: 0...1)
                note("Permission: none. Quiet modes mute all app sounds. Native notifications use the system volume; system-tone choices use the default notification sound.")
            }
        }
    }
    private var privacy: some View {
        Form {
            Section(L("Local by design")) {
                Label(L("Network access blocked by App Sandbox"), systemImage: "network.slash")
                Label(L("No accounts, analytics or network connections"), systemImage: "person.crop.circle.badge.checkmark")
                Label(L("No screen, camera or microphone recording"), systemImage: "video.slash")
                note("Preferences stay local. Daily summaries are optional and off by default. No apps, URLs or exact activity times are saved. No Accessibility, Input Monitoring or Full Disk Access is required. macOS may keep crash logs.")
            }
            Section(L("Notifications")) { notificationPermission }
            Section(L("Optional permissions")) {
                note("Focus sharing is requested only when enabled. Camera state checks request no recording permission. Import/export accesses only your chosen file. Login items are managed by macOS.")
                Text(L("Camera") + ": " + L(model.config.cameraSuppression ? model.cameraActive == nil ? "Unavailable" : "Enabled" : "Off"))
                Text(L("Focus") + ": " + L(model.config.focusSuppression ? model.focusActive == nil ? "Unavailable" : "Enabled" : "Off"))
            }
            Section(L("About Molaway")) {
                Text(L("Developed by Burak Yelkenci with ChatGPT/Codex assistance. Based on Offscreen by Dayo Akinkuowo."))
                Button(L("License & credits")) { license = true }
                note("MIT licensed. No affiliation or endorsement by OpenAI or the original author. A break reminder, not a medical device. Video and meeting detection cannot cover every app or device.")
            }
        }
    }
    private var notificationPermission: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("Status") + ": " + L(model.notifications?.authorization == .authorized ? model.notifications?.alertsEnabled == true ? "Allowed" : "Banners disabled" : model.notifications?.authorization == .denied ? "Denied in System Settings" : "Not requested"))
            Button(L("Request notification permission")) { model.notifications?.request() }
            note("If denied, change Notifications for Molaway in System Settings. No push service or network access is used.")
        }
    }
    private func soundRow(_ title: String, _ key: WritableKeyPath<AppSettings, SoundChoice>) -> some View {
        HStack {
            Picker(L(title), selection: model.settings.binding(key)) { ForEach(SoundChoice.allCases, id: \.self) { Text($0.title).tag($0) } }
            Button { model.play(model.config[keyPath: key]) } label: { Image(systemName: "play.circle") }.buttonStyle(.plain).accessibilityLabel(L("Preview sound") + " · " + L(title))
        }
    }
    private func row(_ key: String, _ value: String) -> some View { HStack { Text(L(key)); Spacer(); Text(value).monospacedDigit().foregroundStyle(.secondary) } }
    private func note(_ key: String) -> some View { Text(L(key)).font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
    private func status(_ key: String) -> some View { Label(L(key), systemImage: "info.circle").font(.caption).foregroundStyle(model.tint) }
    private var licenseText: String {
        let text = Bundle.main.url(forResource: "LICENSE", withExtension: "txt").flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "MIT · Dayo Akinkuowo · Burak Yelkenci"
        return L("Developed by Burak Yelkenci with ChatGPT/Codex assistance. Based on Offscreen by Dayo Akinkuowo.") + "\n\nhttps://github.com/dayaki/offscreen\n\n" + text
    }
}
