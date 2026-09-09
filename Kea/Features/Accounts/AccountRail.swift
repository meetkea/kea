import SwiftUI

struct AccountRail: View {
    @Environment(AppState.self) private var state

    let rename: (AccountProfile) -> Void
    let changeAvatar: (AccountProfile) -> Void
    let clearSession: (AccountProfile) -> Void
    let remove: (AccountProfile) -> Void

    var body: some View {
        VStack(spacing: 6) {
            Image("KeaMark")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.vertical, 2)
                .padding(.bottom, 8)
                .help("Kea")
                .accessibilityLabel("Kea")

            ScrollView(.vertical) {
                LazyVStack(spacing: 4) {
                    ForEach(Array(state.accounts.enumerated()), id: \.element.id) { index, account in
                        Button {
                            state.select(account)
                        } label: {
                            AccountItemView(
                                account: account,
                                avatar: state.avatarImage(for: account),
                                isSelected: state.selectedAccountID == account.id
                            )
                        }
                        .buttonStyle(.plain)
                        .help(accountTooltip(account, at: index))
                        .accessibilityLabel(account.name)
                        .accessibilityValue(AccountShortcut.hint(at: index) ?? "")
                        .accessibilityAddTraits(
                            state.selectedAccountID == account.id ? .isSelected : []
                        )
                        .contextMenu {
                            Button("Open Home") {
                                state.select(account)
                                state.openHome(for: account)
                            }
                            Button("Reload") {
                                state.select(account)
                                state.reload()
                            }
                            Divider()
                            Button("Rename…") { rename(account) }
                            Button("Change Avatar…") { changeAvatar(account) }
                            if account.avatarIdentifier != nil {
                                Button("Remove Custom Avatar") {
                                    state.removeCustomAvatar(from: account)
                                }
                            }
                            AccountAccentMenu(account: account) { accent in
                                state.setAccent(accent, for: account)
                            }
                            Divider()
                            Button("Clear Session…") { clearSession(account) }
                                .disabled(state.isSessionOperationInProgress(for: account.id))
                            Divider()
                            Button("Remove Account…", role: .destructive) { remove(account) }
                                .disabled(state.isSessionOperationInProgress(for: account.id))
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)

            Spacer(minLength: 8)

            Button {
                state.requestAddAccount()
            } label: {
                RailUtilityIcon(systemName: "plus")
            }
            .buttonStyle(.plain)
            .disabled(!state.canAddAccount)
            .help(state.addAccountHelpText)
            .accessibilityLabel("Add Account")

            Button {
                AppLinks.openSupport()
            } label: {
                RailUtilityIcon(systemName: "heart")
            }
            .buttonStyle(.plain)
            .help("Support Kea")
            .accessibilityLabel("Support Kea")

            SettingsLink {
                RailUtilityIcon(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .help("Settings")
            .accessibilityLabel("Settings")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
        .frame(width: 58)
        .background(.ultraThinMaterial)
        .overlay(alignment: .trailing) {
            Divider()
        }
    }

    private func accountTooltip(_ account: AccountProfile, at index: Int) -> String {
        guard let shortcut = AccountShortcut.hint(at: index) else { return account.name }
        return "\(account.name)  \(shortcut)"
    }
}

private struct RailUtilityIcon: View {
    let systemName: String
    @State private var isHovering = false

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .medium))
            .symbolRenderingMode(.hierarchical)
            .frame(width: 36, height: 36)
            .background {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isHovering ? Color.primary.opacity(0.08) : .clear)
            }
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .onHover { isHovering = $0 }
            .animation(.easeOut(duration: 0.12), value: isHovering)
    }
}
