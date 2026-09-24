import Foundation
import Observation
import SwiftUI

/// Loads/saves the settings tree as inspectable JSON in Application Support,
/// with debounced atomic writes. Mutate only through `update` so listeners
/// (engine, schedulers, …) stay in sync.
@Observable
final class SettingsStore {
    private(set) var settings: AppSettings
    private var listeners: [(AppSettings) -> Void] = []
    private var saveTask: Task<Void, Never>?

    static let directoryURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Mola", isDirectory: true)
    static let fileURL = directoryURL.appendingPathComponent("settings.json")

    init() {
        settings = Self.load()
    }

    func addListener(_ listener: @escaping (AppSettings) -> Void) {
        listeners.append(listener)
    }

    func update(_ mutate: (inout AppSettings) -> Void) {
        var copy = settings
        mutate(&copy)
        copy.validate()
        guard copy != settings else { return }
        settings = copy
        for listener in listeners { listener(settings) }
        scheduleSave()
    }

    /// SwiftUI two-way binding into a settings field.
    func binding<T: Equatable>(_ keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { self.settings[keyPath: keyPath] },
            set: { newValue in self.update { $0[keyPath: keyPath] = newValue } }
        )
    }

    func flush() { saveTask?.cancel(); Self.write(settings) }

    // MARK: Persistence

    private static func load() -> AppSettings {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return AppSettings() }
        do {
            var value = try SettingsCodec.read(fileURL)
            value.validate()
            return value
        } catch {
            Log.app.error("Settings could not be decoded; using defaults.")
            return AppSettings()
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [settings] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            Self.write(settings)
        }
    }

    private static func write(_ settings: AppSettings) {
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(settings).write(to: fileURL, options: .atomic)
        } catch {
            Log.app.error("Settings could not be saved.")
        }
    }
}
