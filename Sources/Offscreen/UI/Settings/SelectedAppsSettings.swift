import SwiftUI
import UniformTypeIdentifiers

struct SelectedAppsSettings: View {
    let model: AppContainer
    @State private var selectionError = false

    var body: some View {
        Section(L("Selected apps")) {
            Toggle(L("Quiet alerts when a selected app is in front"), isOn: model.settings.binding(\.selectedAppSuppression))
            Text(L("Only your chosen app list is saved in preferences and settings backups. No app usage history or file paths are stored."))
                .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            ForEach(model.config.selectedAppBundleIDs, id: \.self) { id in
                HStack {
                    Text(displayName(id)).lineLimit(2)
                    Spacer()
                    Button(L("Remove")) { model.settings.update { $0.selectedAppBundleIDs.removeAll { $0 == id } } }
                        .accessibilityLabel(L("Remove") + " · " + displayName(id))
                }
            }
            Button(L("Choose app…")) { chooseApp() }
                .disabled(model.config.selectedAppBundleIDs.count >= SelectedAppPolicy.maximumApps)
            Text(L("Up to 32 apps. A background app does not quiet alerts. Unavailable status does not quiet alerts."))
                .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if selectionError {
                Text(L("Could not use that app. Choose another application."))
                    .font(.caption).foregroundStyle(.red)
            }
            if model.config.selectedAppSuppression {
                Label(L(model.selectedAppActive == nil ? "Selected app status unavailable" : model.selectedAppActive == true ? "Selected app in front" : "No selected app in front"), systemImage: "info.circle")
                    .font(.caption).foregroundStyle(model.tint)
            }
        }
    }

    private func displayName(_ id: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return id }
        return FileManager.default.displayName(atPath: url.path)
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        // Reading Info.plist does not load or launch the selected executable.
        guard let id = Bundle(url: url)?.bundleIdentifier, SelectedAppPolicy.isValidID(id) else {
            selectionError = true
            return
        }
        selectionError = false
        model.settings.update {
            if !$0.selectedAppBundleIDs.contains(id) { $0.selectedAppBundleIDs.append(id) }
        }
    }
}
