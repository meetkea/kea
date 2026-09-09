import SwiftUI

enum AccountAccent: String, CaseIterable, Identifiable {
    case automatic
    case blue
    case cyan
    case green
    case yellow
    case orange
    case red
    case pink
    case purple
    case indigo
    case gray

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var storedIdentifier: String? {
        self == .automatic ? nil : rawValue
    }

    var color: Color {
        switch self {
        case .automatic, .blue: .blue
        case .cyan: .cyan
        case .green: .green
        case .yellow: .yellow
        case .orange: .orange
        case .red: .red
        case .pink: .pink
        case .purple: .purple
        case .indigo: .indigo
        case .gray: .gray
        }
    }

    static func selection(for identifier: String?) -> AccountAccent {
        guard let identifier, let accent = AccountAccent(rawValue: identifier) else {
            return .automatic
        }
        return accent
    }
}
