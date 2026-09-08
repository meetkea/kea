import SwiftUI

struct AccountRail: View {
    @Environment(AppState.self) private var state
    @Environment(AuthenticationAccessService.self) private var authentication

    let rename: (AccountProfile) -> Void
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
                    ForEach(state.accounts) { account in
                        Button {
                            state.select(account)
                        } label: {
                            AccountItemView(
                                account: account,
                                isSelected: state.selectedAccountID == account.id
                            )
                        }
                        .buttonStyle(.plain)
                        .help(account.name)
                        .contextMenu {
                            Button("Reload") {
                                state.select(account)
                                state.reload()
                            }
                            Button("Rename…") { rename(account) }
                            Button("Open Home") {
                                state.select(account)
                                state.openHome(for: account)
                            }
                            Button("Open Passwords…") {
                                Task { await authentication.openPasswords() }
                            }
                            Divider()
                            Button("Clear Session…") { clearSession(account) }
                                .disabled(state.isSessionOperationInProgress(for: account.id))
                            Button("Remove Account…", role: .destructive) { remove(account) }
                                .disabled(state.isSessionOperationInProgress(for: account.id))
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)

            Spacer(minLength: 8)

            Button {
                state.isPresentingAddAccount = true
            } label: {
                RailUtilityIcon(systemName: "plus")
            }
            .buttonStyle(.plain)
            .help("Add Account")
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
