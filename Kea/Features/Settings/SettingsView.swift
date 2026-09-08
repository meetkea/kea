import SwiftUI

private enum SettingsAccountAction: Identifiable {
    case clear(AccountProfile)
    case remove(AccountProfile)

    var id: String {
        switch self {
        case .clear(let account): "clear-\(account.id)"
        case .remove(let account): "remove-\(account.id)"
        }
    }
}

struct SettingsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            AccountsSettingsView()
                .tabItem { Label("Accounts", systemImage: "person.2") }
            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 560, height: 390)
    }
}

private struct GeneralSettingsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var preferences = state.preferences

        Form {
            Section("General") {
                Toggle("Open last active account on launch", isOn: $preferences.openLastAccount)
                Toggle("Restore last visited X page", isOn: $preferences.restoreLastPage)
                Toggle("Open external links in the default browser", isOn: $preferences.openExternalLinks)
            }

            Section("Appearance") {
                Picker("Theme", selection: $preferences.appearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct AccountsSettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.openWindow) private var openWindow
    @State private var accountToRename: AccountProfile?
    @State private var pendingAction: SettingsAccountAction?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Accounts")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("Add Account") {
                    openWindow(id: "main")
                    state.isPresentingAddAccount = true
                }
            }

            if state.accounts.isEmpty {
                ContentUnavailableView(
                    "No Accounts",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text("Add an account from the main Kea window.")
                )
            } else {
                List(state.accounts) { account in
                    HStack {
                        AccountItemView(
                            account: account,
                            isSelected: state.selectedAccountID == account.id
                        )
                        .scaleEffect(0.82)

                        Text(account.name)
                        Spacer()

                        Menu {
                            Button("Rename…") { accountToRename = account }
                            Button("Clear Session…") { pendingAction = .clear(account) }
                                .disabled(state.isSessionOperationInProgress(for: account.id))
                            Button("Remove Account…", role: .destructive) { pendingAction = .remove(account) }
                                .disabled(state.isSessionOperationInProgress(for: account.id))
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        .accessibilityLabel("Actions for \(account.name)")
                    }
                }
            }
        }
        .padding(20)
        .sheet(item: $accountToRename) { account in
            AccountEditorView(
                title: "Rename Account",
                actionTitle: "Rename",
                initialName: account.name
            ) {
                state.rename(account, to: $0)
            }
        }
        .confirmationDialog(
            "Delete local X session?",
            isPresented: Binding(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let pendingAction {
                switch pendingAction {
                case .clear(let account):
                    Button("Clear Session", role: .destructive) {
                        Task { await state.clearSession(for: account) }
                    }
                case .remove(let account):
                    Button("Remove Account", role: .destructive) {
                        Task { await state.remove(account) }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Kea will delete the selected account's local WebKit session. This cannot be undone.")
        }
    }
}

private struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image("KeaMark")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Text("Kea")
                .font(.title.weight(.semibold))
            Text("App for X on Mac.")
                .font(.title3)
            Text("A free, open-source multi-account client for X on macOS.")
                .foregroundStyle(.secondary)
            Text("Kea is an independent open-source project and is not affiliated with X.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            HStack {
                Link("usekea.com", destination: AppLinks.website)
                if let github = AppLinks.github {
                    Link("GitHub", destination: github)
                }
                Link("Support Kea", destination: AppLinks.support)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
