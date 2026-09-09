import Foundation

struct AccountShortcutAssignment: Equatable {
    let accountID: UUID
    let number: Int
}

enum AccountShortcut {
    static func assignments(for accounts: [AccountProfile]) -> [AccountShortcutAssignment] {
        Array(accounts.prefix(9).enumerated()).map { index, account in
            AccountShortcutAssignment(accountID: account.id, number: index + 1)
        }
    }

    static func hint(at index: Int) -> String? {
        guard (0..<9).contains(index) else { return nil }
        return "⌘\(index + 1)"
    }
}
