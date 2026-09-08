import SwiftUI

struct AccountRail: View {
    @Environment(AppState.self) private var state

    let rename: (AccountProfile) -> Void
    let clearSession: (AccountProfile) -> Void
    let remove: (AccountProfile) -> Void

    var body: some View {
        VStack(spacing: 6) {
            Image("KeaMark")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .padding(.bottom, 6)
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
                Image(systemName: "plus")
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .help("Add Account")
            .accessibilityLabel("Add Account")

            SettingsLink {
                Image(systemName: "gearshape")
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .help("Settings")
            .accessibilityLabel("Settings")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .frame(width: 62)
        .background(.ultraThinMaterial)
        .overlay(alignment: .trailing) {
            Divider()
        }
    }
}
