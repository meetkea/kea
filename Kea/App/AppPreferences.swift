import Foundation
import Observation

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

@MainActor
@Observable
final class AppPreferences {
    private enum Key {
        static let selectedAccountID = "selectedAccountID"
        static let openLastAccount = "openLastAccount"
        static let restoreLastPage = "restoreLastPage"
        static let openExternalLinks = "openExternalLinks"
        static let appearance = "appearance"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var selectedAccountID: UUID? {
        didSet { defaults.set(selectedAccountID?.uuidString, forKey: Key.selectedAccountID) }
    }
    var openLastAccount: Bool {
        didSet { defaults.set(openLastAccount, forKey: Key.openLastAccount) }
    }
    var restoreLastPage: Bool {
        didSet { defaults.set(restoreLastPage, forKey: Key.restoreLastPage) }
    }
    var openExternalLinks: Bool {
        didSet { defaults.set(openExternalLinks, forKey: Key.openExternalLinks) }
    }
    var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedAccountID = defaults.string(forKey: Key.selectedAccountID).flatMap(UUID.init(uuidString:))
        openLastAccount = defaults.object(forKey: Key.openLastAccount) as? Bool ?? true
        restoreLastPage = defaults.object(forKey: Key.restoreLastPage) as? Bool ?? true
        openExternalLinks = defaults.object(forKey: Key.openExternalLinks) as? Bool ?? true
        appearance = defaults.string(forKey: Key.appearance).flatMap(AppAppearance.init(rawValue:)) ?? .system
    }
}
