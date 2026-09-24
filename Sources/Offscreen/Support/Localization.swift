import Foundation
import Observation

@Observable final class Localization {
    static let shared = Localization()
    var language: AppLanguage = .system
    @ObservationIgnored private var bundles: [String: Bundle] = [:]
    var code: String {
        if language != .system { return language.rawValue }
        return Locale.preferredLanguages.first?.hasPrefix("tr") == true ? "tr" : "en"
    }
    func text(_ key: String) -> String {
        let code = code
        if bundles[code] == nil, let path = Bundle.main.path(forResource: code, ofType: "lproj") {
            bundles[code] = Bundle(path: path)
        }
        guard let bundle = bundles[code] else { return key }
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
}
func L(_ key: String) -> String { Localization.shared.text(key) }
func minutes(_ count: Int) -> String { "\(count) " + L("min") }
