import AppKit
import SwiftUI

struct AppCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let state: AppState
    let authentication: AuthenticationAccessService

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
                openWindow(id: "main")
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
                .disabled(state.activeSession == nil)
            Divider()
            Button("Actual Size") { state.actualSize() }
                .keyboardShortcut("0", modifiers: .command)
                .disabled(state.activeSession == nil)
            Button("Zoom In") { state.zoomIn() }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(state.activeSession == nil)
            Button("Zoom Out") { state.zoomOut() }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(state.activeSession == nil)
        }

        CommandGroup(replacing: .help) {
            Button("Open Passwords…") {
                Task { await authentication.openPasswords() }
            }

            if authentication.canRequestPasskeyAccess {
                Button("Allow Passkey Access…") {
                    Task { await authentication.requestPasskeyAccess() }
                }
                .disabled(authentication.isRequestingPasskeyAccess)
            }

            Divider()
            Link("Kea Website", destination: AppLinks.website)
            Button("Support Kea") {
                AppLinks.openSupport()
            }

            Divider()
            if let github = AppLinks.github {
                Link("GitHub", destination: github)
            } else {
                Button("GitHub") {}
                    .disabled(true)
            }
        }
    }
}

enum AppLinks {
    static let website = URL(string: "https://usekea.com")!
    static let github = URL(string: "https://github.com/meetkea/kea")
    static let support = URL(string: "https://usekea.com/support")!

    @MainActor
    static func openSupport() {
        KeaLogger.app.info("Opening the Kea support page in the default browser")
        NSWorkspace.shared.open(support)
    }
}
