import AppKit
import SwiftData
import SwiftUI

@main
@MainActor
struct KeaApp: App {
    private let persistence: PersistenceController
    @State private var state: AppState
    @State private var authentication = AuthenticationAccessService()

    init() {
        let persistence = PersistenceController.make()
        self.persistence = persistence
        _state = State(initialValue: AppState(
            modelContext: persistence.container.mainContext,
            performAvatarCleanup: true,
            startupError: persistence.startupError
        ))
    }

    var body: some Scene {
        Window("Kea", id: "main") {
            MainWindowView()
                .environment(state)
                .environment(authentication)
                .modelContainer(persistence.container)
                .preferredColorScheme(preferredColorScheme)
        }
        .defaultSize(width: 1180, height: 760)
        .windowResizability(.contentMinSize)
        .commands {
            AppCommands(state: state, authentication: authentication)
        }

        Settings {
            SettingsView()
                .environment(state)
                .environment(authentication)
                .modelContainer(persistence.container)
                .preferredColorScheme(preferredColorScheme)
        }

        MenuBarExtra(
            "Kea",
            systemImage: MenuBarIcon.systemName,
            isInserted: Binding(
                get: { state.preferences.showInMenuBar },
                set: { state.preferences.showInMenuBar = $0 }
            )
        ) {
            KeaMenuBarView(state: state)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch state.preferences.appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

private enum MenuBarIcon {
    // The supplied Kea artwork is full color; keep this isolated template icon
    // easy to replace when a dedicated monochrome asset is available.
    static let systemName = "bird.fill"
}

private struct KeaMenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    let state: AppState

    var body: some View {
        Menu("Accounts") {
            if state.accounts.isEmpty {
                Text("No Accounts")
            } else {
                ForEach(state.accounts) { account in
                    Button {
                        openMainWindow(selecting: account)
                    } label: {
                        if state.selectedAccountID == account.id {
                            Label(account.name, systemImage: "checkmark")
                        } else {
                            Text(account.name)
                        }
                    }
                    .accessibilityLabel(
                        state.selectedAccountID == account.id
                            ? "\(account.name), selected account"
                            : account.name
                    )
                }
            }
        }

        Divider()

        Button("Open Kea") {
            openMainWindow()
        }
        Button("Add Account") {
            openMainWindow()
            state.isPresentingAddAccount = true
        }
        Button("Support Kea") {
            AppLinks.openSupport()
        }

        Divider()

        Button("Quit Kea") {
            NSApplication.shared.terminate(nil)
        }
    }

    private func openMainWindow(selecting account: AccountProfile? = nil) {
        if let account {
            state.select(account)
        }
        openWindow(id: "main")
        NSApp.activate()
    }
}
