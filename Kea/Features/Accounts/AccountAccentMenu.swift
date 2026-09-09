import SwiftUI

struct AccountAccentMenu: View {
    let account: AccountProfile
    let setAccent: (AccountAccent) -> Void

    private var selectedAccent: AccountAccent {
        AccountAccent.selection(for: account.accentIdentifier)
    }

    var body: some View {
        Menu("Accent Color") {
            ForEach(AccountAccent.allCases) { accent in
                Button {
                    setAccent(accent)
                } label: {
                    HStack {
                        Label(accent.title, systemImage: "circle.fill")
                        if accent == selectedAccent {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .tint(accent.color)
                .accessibilityLabel("\(account.name) accent color: \(accent.title)")
            }
        }
        .accessibilityLabel("\(account.name) accent color: \(selectedAccent.title)")
    }
}
