import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppState {
    private(set) var accounts: [AccountProfile] = []
    var selectedAccountID: UUID?
    var isPresentingAddAccount = false
    var errorMessage: String?

    let preferences: AppPreferences
    let webViewPool: WebViewPool

    @ObservationIgnored private let modelContext: ModelContext

    init(
        modelContext: ModelContext,
        preferences: AppPreferences = AppPreferences(),
        startupError: String? = nil
    ) {
        self.modelContext = modelContext
        self.preferences = preferences
        webViewPool = WebViewPool()
        errorMessage = startupError
        refreshAccounts()

        if preferences.openLastAccount,
           let remembered = preferences.selectedAccountID,
           accounts.contains(where: { $0.id == remembered }) {
            selectedAccountID = remembered
        } else {
            selectedAccountID = accounts.first?.id
        }
    }

    var selectedAccount: AccountProfile? {
        accounts.first { $0.id == selectedAccountID }
    }

    var activeSession: BrowserSession? {
        webViewPool.existingSession(for: selectedAccountID)
    }

    func select(_ account: AccountProfile) {
        selectedAccountID = account.id
        preferences.selectedAccountID = account.id
        account.lastOpenedAt = Date()
        saveMetadata()
    }

    func selectAccount(at index: Int) {
        guard accounts.indices.contains(index) else { return }
        select(accounts[index])
    }

    func addAccount(named rawName: String) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let nextSortOrder = (accounts.map(\.sortOrder).max() ?? -1) + 1
        let account = AccountProfile(name: name, sortOrder: nextSortOrder)
        modelContext.insert(account)
        saveMetadata()
        refreshAccounts()
        select(account)
    }

    func rename(_ account: AccountProfile, to rawName: String) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        account.name = name
        saveMetadata()
        refreshAccounts()
    }

    func remove(_ account: AccountProfile) async {
        let previousSelection = selectedAccountID
        if selectedAccountID == account.id {
            selectedAccountID = AccountSelectionPolicy.replacementID(
                afterRemoving: account.id,
                from: accounts.map(\.id)
            )
            preferences.selectedAccountID = selectedAccountID
        }

        do {
            try await webViewPool.deleteSession(for: account)
            modelContext.delete(account)
            try modelContext.save()
            refreshAccounts()
        } catch {
            selectedAccountID = previousSelection
            preferences.selectedAccountID = previousSelection
            errorMessage = "Kea could not delete the local session for \"\(account.name)\". The account was not removed."
        }
    }

    func clearSession(for account: AccountProfile) async {
        do {
            try await webViewPool.deleteSession(for: account)
            account.lastURLString = nil
            try modelContext.save()
        } catch {
            errorMessage = "Kea could not clear the local session for \"\(account.name)\"."
        }
    }

    func browserSession(for account: AccountProfile) -> BrowserSession {
        webViewPool.session(
            for: account,
            restoreLastPage: preferences.restoreLastPage,
            openExternalLinks: { [weak self] in self?.preferences.openExternalLinks ?? true },
            onSafeURLChange: { [weak self, weak account] value in
                guard let self, let account else { return }
                account.lastURLString = value
                self.saveMetadata()
            }
        )
    }

    func reload() { webViewPool.reload(selectedAccountID) }
    func openHome(for account: AccountProfile) { webViewPool.openHome(account.id) }
    func goBack() { webViewPool.goBack(selectedAccountID) }
    func goForward() { webViewPool.goForward(selectedAccountID) }
    func zoomIn() { webViewPool.zoom(selectedAccountID, delta: 0.1) }
    func zoomOut() { webViewPool.zoom(selectedAccountID, delta: -0.1) }
    func actualSize() { webViewPool.actualSize(selectedAccountID) }

    private func refreshAccounts() {
        do {
            let descriptor = FetchDescriptor<AccountProfile>(
                sortBy: [SortDescriptor(\AccountProfile.sortOrder), SortDescriptor(\AccountProfile.createdAt)]
            )
            accounts = try modelContext.fetch(descriptor)

            if let selectedAccountID,
               !accounts.contains(where: { $0.id == selectedAccountID }) {
                self.selectedAccountID = accounts.first?.id
                preferences.selectedAccountID = self.selectedAccountID
            }
        } catch {
            accounts = []
            errorMessage = "Kea could not load your local account list."
        }
    }

    private func saveMetadata() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Kea could not save that change."
        }
    }
}
