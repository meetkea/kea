import SwiftUI

private enum PendingAccountAction: Identifiable {
    case clear(AccountProfile)
    case remove(AccountProfile)

    var id: String {
        switch self {
        case .clear(let account): "clear-\(account.id)"
        case .remove(let account): "remove-\(account.id)"
        }
    }

    var account: AccountProfile {
        switch self {
        case .clear(let account), .remove(let account): account
        }
    }
}

struct MainWindowView: View {
    @Environment(AppState.self) private var state
    @Environment(\.openSettings) private var openSettings

    @State private var accountToRename: AccountProfile?
    @State private var pendingAction: PendingAccountAction?

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                AccountRail(
                    rename: { accountToRename = $0 },
                    changeAvatar: chooseAvatar,
                    clearSession: { pendingAction = .clear($0) },
                    remove: { pendingAction = .remove($0) }
                )

                if let account = state.selectedAccount {
                    BrowserAccountView(account: account)
                        .id(account.id)
                } else {
                    BrowserEmptyState {
                        state.isPresentingAddAccount = true
                    }
                }
            }

            if state.isCommandPalettePresented {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()
                    .onTapGesture { state.isCommandPalettePresented = false }

                CommandPaletteView(
                    items: commandPaletteItems,
                    accountForID: { id in state.accounts.first { $0.id == id } },
                    avatarForAccount: state.avatarImage,
                    perform: performCommand,
                    dismiss: { state.isCommandPalettePresented = false }
                )
                .padding(24)
                .transition(.scale(scale: 0.98).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.12), value: state.isCommandPalettePresented)
        .frame(minWidth: 850, minHeight: 600)
        .sheet(isPresented: Binding(
            get: { state.isPresentingAddAccount },
            set: { state.isPresentingAddAccount = $0 }
        )) {
            AccountEditorView(title: "Add X Account", actionTitle: "Add Account") {
                state.addAccount(named: $0)
            }
        }
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
            confirmationTitle,
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
                    Button("Remove", role: .destructive) {
                        Task { await state.remove(account) }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(confirmationMessage)
        }
        .alert("Kea", isPresented: Binding(
            get: { state.errorMessage != nil },
            set: { if !$0 { state.errorMessage = nil } }
        )) {
            Button("OK") { state.errorMessage = nil }
        } message: {
            Text(state.errorMessage ?? "")
        }
    }

    private var commandPaletteItems: [CommandPaletteItem] {
        CommandPaletteCatalog.items(
            accounts: state.accounts,
            hasActiveSession: state.activeSession != nil,
            canGoBack: state.activeSession?.state.canGoBack == true,
            canGoForward: state.activeSession?.state.canGoForward == true
        )
    }

    private func chooseAvatar(for account: AccountProfile) {
        guard let url = AvatarPicker.chooseImage() else { return }
        state.replaceAvatar(for: account, with: url)
    }

    private func performCommand(_ command: KeaCommand) {
        state.isCommandPalettePresented = false

        switch command {
        case .selectAccount(let accountID):
            state.selectAccountFromCommandPalette(accountID)
        case .addAccount:
            state.isPresentingAddAccount = true
        case .reload:
            state.reload()
        case .back:
            state.goBack()
        case .forward:
            state.goForward()
        case .open(let destination):
            state.open(destination)
        case .settings:
            openSettings()
        case .support:
            AppLinks.openSupport()
        }
    }

    private var confirmationTitle: String {
        guard let pendingAction else { return "" }
        switch pendingAction {
        case .clear(let account): return "Clear session for \"\(account.name)\"?"
        case .remove(let account): return "Remove \"\(account.name)\"?"
        }
    }

    private var confirmationMessage: String {
        guard let pendingAction else { return "" }
        switch pendingAction {
        case .clear:
            return "This keeps the account label but deletes its local X session. You will need to sign in again."
        case .remove:
            return "This removes the account from Kea and deletes its local X session. You can sign in again later."
        }
    }
}

private struct BrowserAccountView: View {
    @Environment(AppState.self) private var state
    let account: AccountProfile

    var body: some View {
        Group {
            if state.isSessionOperationInProgress(for: account.id) {
                ProgressView("Updating \(account.name)…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let session = state.webViewPool.existingSession(for: account.id) {
                BrowserPane(session: session)
            } else {
                ProgressView("Opening \(account.name)…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: state.isSessionOperationInProgress(for: account.id)) {
            guard !state.isSessionOperationInProgress(for: account.id) else { return }
            guard state.webViewPool.existingSession(for: account.id) == nil else { return }
            _ = state.browserSession(for: account)
        }
    }
}
