import AppKit
import SwiftUI

struct AppCommands: Commands {
    let state: AppState

    var body: some Commands {
        CommandMenu("Accounts") {
            ForEach(Array(state.accounts.prefix(9).enumerated()), id: \.element.id) { index, account in
                Button(account.name) {
                    state.select(account)
                }
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
            }

            if !state.accounts.isEmpty {
                Divider()
            }

            Button("Add Account…") {
                state.isPresentingAddAccount = true
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])

            SettingsLink {
                Text("Manage Accounts…")
            }
        }

        CommandGroup(after: .toolbar) {
            Button("Back") { state.goBack() }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(state.activeSession?.state.canGoBack != true)
            Button("Forward") { state.goForward() }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(state.activeSession?.state.canGoForward != true)
            Button("Reload") { state.reload() }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(state.selectedAccount == nil)
            Divider()
            Button("Actual Size") { state.actualSize() }
                .keyboardShortcut("0", modifiers: .command)
            Button("Zoom In") { state.zoomIn() }
                .keyboardShortcut("+", modifiers: .command)
            Button("Zoom Out") { state.zoomOut() }
                .keyboardShortcut("-", modifiers: .command)
        }

        CommandGroup(replacing: .help) {
            Link("Kea Website", destination: AppLinks.website)
            if let github = AppLinks.github {
                Link("GitHub", destination: github)
            } else {
                Button("GitHub") {}
                    .disabled(true)
            }
            Link("Support Kea", destination: AppLinks.support)
        }
    }
}

enum AppLinks {
    static let website = URL(string: "https://usekea.com")!
    static let github = URL(string: "https://github.com/meetkea/kea")
    static let support = URL(string: "https://usekea.com/support")!
}
