import AppKit
import UniformTypeIdentifiers

enum SettingsTransfer {
    static func export(_ model: AppContainer) {
        let panel = NSSavePanel(); panel.allowedContentTypes = [.json]; panel.nameFieldStringValue = "Molaway-settings.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
        do { try SettingsCodec.export(model.config).write(to: url, options: .atomic); model.feedback = L("Settings exported.") }
        catch { model.feedback = L("Could not export settings.") }
    }
    static func importSettings(_ model: AppContainer) {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]; panel.allowsMultipleSelection = false; panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            var settings = try SettingsCodec.read(url, strict: true)
            settings.didFinishWelcome = true
            settings.cameraSuppression = false; settings.focusSuppression = false
            model.settings.update { $0 = settings }
            model.feedback = L("Settings imported. Permission features remain off.")
        } catch { model.feedback = L("Invalid settings file. Your settings were not changed.") }
    }
}
