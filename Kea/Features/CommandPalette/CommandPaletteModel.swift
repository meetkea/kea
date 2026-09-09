import Foundation

enum CommandPaletteSection: String, CaseIterable {
    case accounts = "Accounts"
    case actions = "Actions"
}

enum KeaCommand: Hashable {
    case selectAccount(UUID)
    case addAccount
    case reload
    case back
    case forward
    case open(XDestination)
    case settings
    case support
}

struct CommandPaletteItem: Identifiable, Hashable {
    let id: String
    let title: String
    let section: CommandPaletteSection
    let systemImage: String
    let shortcutHint: String?
    let searchTerms: [String]
    let command: KeaCommand
    let isEnabled: Bool

    var searchableText: String {
        ([title] + searchTerms).joined(separator: " ").lowercased()
    }
}

enum CommandPaletteCatalog {
    static func items(
        accounts: [AccountProfile],
        hasActiveSession: Bool,
        canGoBack: Bool,
        canGoForward: Bool
    ) -> [CommandPaletteItem] {
        let accountItems = Array(accounts.enumerated()).map { index, account in
            CommandPaletteItem(
                id: "account-\(account.id.uuidString)",
                title: account.name,
                section: .accounts,
                systemImage: "person.crop.circle",
                shortcutHint: AccountShortcut.hint(at: index),
                searchTerms: ["account", "switch"],
                command: .selectAccount(account.id),
                isEnabled: true
            )
        }

        var actions = [
            CommandPaletteItem(
                id: "add-account",
                title: "Add Account",
                section: .actions,
                systemImage: "plus",
                shortcutHint: "⇧⌘A",
                searchTerms: ["new", "profile"],
                command: .addAccount,
                isEnabled: true
            )
        ]

        if hasActiveSession {
            actions += [
                CommandPaletteItem(
                    id: "reload",
                    title: "Reload",
                    section: .actions,
                    systemImage: "arrow.clockwise",
                    shortcutHint: "⌘R",
                    searchTerms: ["refresh"],
                    command: .reload,
                    isEnabled: true
                ),
                CommandPaletteItem(
                    id: "back",
                    title: "Back",
                    section: .actions,
                    systemImage: "chevron.backward",
                    shortcutHint: "⌘[",
                    searchTerms: ["previous"],
                    command: .back,
                    isEnabled: canGoBack
                ),
                CommandPaletteItem(
                    id: "forward",
                    title: "Forward",
                    section: .actions,
                    systemImage: "chevron.forward",
                    shortcutHint: "⌘]",
                    searchTerms: ["next"],
                    command: .forward,
                    isEnabled: canGoForward
                ),
                navigationItem(.home, title: "Open Home", systemImage: "house", searchTerms: ["timeline"]),
                navigationItem(
                    .notifications,
                    title: "Open Notifications",
                    systemImage: "bell",
                    searchTerms: ["alerts", "mentions"]
                ),
                navigationItem(
                    .messages,
                    title: "Open Messages",
                    systemImage: "envelope",
                    searchTerms: ["dm", "private"]
                ),
                navigationItem(
                    .bookmarks,
                    title: "Open Bookmarks",
                    systemImage: "bookmark",
                    searchTerms: ["saved"]
                )
            ]
        }

        actions += [
            CommandPaletteItem(
                id: "settings",
                title: "Settings",
                section: .actions,
                systemImage: "gearshape",
                shortcutHint: "⌘,",
                searchTerms: ["preferences"],
                command: .settings,
                isEnabled: true
            ),
            CommandPaletteItem(
                id: "support",
                title: "Support Kea",
                section: .actions,
                systemImage: "heart",
                shortcutHint: nil,
                searchTerms: ["help", "donate"],
                command: .support,
                isEnabled: true
            )
        ]

        return accountItems + actions
    }

    static func filtered(_ items: [CommandPaletteItem], query: String) -> [CommandPaletteItem] {
        let tokens = query
            .lowercased()
            .split(whereSeparator: \Character.isWhitespace)
            .map(String.init)
        guard !tokens.isEmpty else { return items }
        return items.filter { item in
            tokens.allSatisfy(item.searchableText.contains)
        }
    }

    private static func navigationItem(
        _ destination: XDestination,
        title: String,
        systemImage: String,
        searchTerms: [String]
    ) -> CommandPaletteItem {
        CommandPaletteItem(
            id: "open-\(destination.rawValue)",
            title: title,
            section: .actions,
            systemImage: systemImage,
            shortcutHint: nil,
            searchTerms: searchTerms,
            command: .open(destination),
            isEnabled: true
        )
    }
}
