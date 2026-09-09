import AppKit
import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppState {
    private(set) var accounts: [AccountProfile] = []
    private(set) var sessionOperationAccountIDs: Set<UUID> = []
    var selectedAccountID: UUID?
    var isPresentingAddAccount = false
    var isCommandPalettePresented = false
    var errorMessage: String?

    let preferences: AppPreferences
    let webViewPool: WebViewPool
    let avatarStorage: AvatarStorage

    @ObservationIgnored private let modelContext: ModelContext

    init(
        modelContext: ModelContext,
        preferences: AppPreferences = AppPreferences(),
        avatarStorage: AvatarStorage = AvatarStorage(),
        performAvatarCleanup: Bool = false,
        startupError: String? = nil
    ) {
        self.modelContext = modelContext
        self.preferences = preferences
        self.avatarStorage = avatarStorage
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
        preferences.selectedAccountID = selectedAccountID

        if performAvatarCleanup, startupError == nil {
            cleanupOrphanedAvatars()
        }
    }

    var selectedAccount: AccountProfile? {
        accounts.first { $0.id == selectedAccountID }
    }

    var activeSession: BrowserSession? {
        webViewPool.existingSession(for: selectedAccountID)
    }

    func select(_ account: AccountProfile) {
        guard accounts.contains(where: { $0.id == account.id }) else { return }
        selectedAccountID = account.id
        preferences.selectedAccountID = account.id
        account.lastOpenedAt = Date()
        saveMetadata()
    }

    func selectAccount(at index: Int) {
        guard accounts.indices.contains(index) else { return }
        select(accounts[index])
    }

    func selectAccountFromCommandPalette(_ accountID: UUID) {
        guard let account = accounts.first(where: { $0.id == accountID }) else { return }
        select(account)
        isCommandPalettePresented = false
    }

    func addAccount(named rawName: String) {
        guard let name = AccountName.normalized(rawName) else { return }

        let nextSortOrder = (accounts.map(\.sortOrder).max() ?? -1) + 1
        let account = AccountProfile(name: name, sortOrder: nextSortOrder)
        modelContext.insert(account)

        do {
            try modelContext.save()
            refreshAccounts()
            select(account)
            KeaLogger.accounts.info("Added a local account profile")
        } catch {
            modelContext.rollback()
            refreshAccounts()
            KeaLogger.accounts.error("Failed to persist a new account profile")
            errorMessage = "Kea could not add that account."
        }
    }

    func rename(_ account: AccountProfile, to rawName: String) {
        guard let name = AccountName.normalized(rawName) else { return }
        let previousName = account.name
        account.name = name

        do {
            try modelContext.save()
            refreshAccounts()
            KeaLogger.accounts.info("Renamed a local account profile")
        } catch {
            account.name = previousName
            modelContext.rollback()
            refreshAccounts()
            KeaLogger.accounts.error("Failed to persist an account rename")
            errorMessage = "Kea could not rename that account."
        }
    }

    func setAccent(_ accent: AccountAccent, for account: AccountProfile) {
        let previousIdentifier = account.accentIdentifier
        account.accentIdentifier = accent.storedIdentifier

        do {
            try modelContext.save()
            refreshAccounts()
            KeaLogger.accounts.info("Changed local account accent")
        } catch {
            account.accentIdentifier = previousIdentifier
            modelContext.rollback()
            refreshAccounts()
            KeaLogger.accounts.error("Failed to persist a local account accent")
            errorMessage = "Kea could not change that account color."
        }
    }

    func replaceAvatar(for account: AccountProfile, with sourceURL: URL) {
        let previousIdentifier = account.avatarIdentifier
        var newIdentifier: String?

        do {
            newIdentifier = try avatarStorage.saveAvatar(from: sourceURL)
            account.avatarIdentifier = newIdentifier
            try modelContext.save()
            try? avatarStorage.deleteAvatar(previousIdentifier)
            refreshAccounts()
            KeaLogger.accounts.info("Changed a local account avatar")
        } catch {
            account.avatarIdentifier = previousIdentifier
            modelContext.rollback()
            try? avatarStorage.deleteAvatar(newIdentifier)
            refreshAccounts()
            KeaLogger.accounts.error("Failed to save a local account avatar")
            errorMessage = error.localizedDescription
        }
    }

    func removeCustomAvatar(from account: AccountProfile) {
        guard let previousIdentifier = account.avatarIdentifier else { return }
        account.avatarIdentifier = nil

        do {
            try modelContext.save()
            try? avatarStorage.deleteAvatar(previousIdentifier)
            refreshAccounts()
            KeaLogger.accounts.info("Removed a local account avatar")
        } catch {
            account.avatarIdentifier = previousIdentifier
            modelContext.rollback()
            refreshAccounts()
            KeaLogger.accounts.error("Failed to remove a local account avatar")
            errorMessage = "Kea could not remove that custom avatar."
        }
    }

    func avatarImage(for account: AccountProfile) -> NSImage? {
        avatarStorage.image(for: account.avatarIdentifier)
    }

    func remove(_ account: AccountProfile) async {
        guard sessionOperationAccountIDs.insert(account.id).inserted else { return }
        defer { sessionOperationAccountIDs.remove(account.id) }

        let previousSelection = selectedAccountID
        let avatarIdentifier = account.avatarIdentifier
        let hadLoadedSession = webViewPool.existingSession(for: account.id) != nil
        var storeWasDeleted = false

        if selectedAccountID == account.id {
            selectedAccountID = AccountSelectionPolicy.replacementID(
                afterRemoving: account.id,
                from: accounts.map(\.id)
            )
            preferences.selectedAccountID = selectedAccountID
        }

        do {
            try await webViewPool.deleteSession(for: account)
            storeWasDeleted = true
            modelContext.delete(account)
            try modelContext.save()
            try? avatarStorage.deleteAvatar(avatarIdentifier)
            refreshAccounts()
            KeaLogger.accounts.info("Removed a local account profile and its isolated session")
        } catch {
            modelContext.rollback()
            refreshAccounts()
            selectedAccountID = previousSelection
            preferences.selectedAccountID = previousSelection

            if hadLoadedSession || previousSelection == account.id {
                _ = browserSession(for: account)
            }

            KeaLogger.accounts.error("Failed to complete account removal")
            errorMessage = storeWasDeleted
                ? "The X session was deleted, but Kea could not remove the local account label. The account now has a fresh signed-out session."
                : "Kea could not delete the local X session. The account was not removed."
        }
    }

    func clearSession(for account: AccountProfile) async {
        guard sessionOperationAccountIDs.insert(account.id).inserted else { return }
        defer { sessionOperationAccountIDs.remove(account.id) }

        var storeWasDeleted = false
        do {
            try await webViewPool.deleteSession(for: account)
            storeWasDeleted = true
            account.lastURLString = nil
            try modelContext.save()
            _ = browserSession(for: account)
            KeaLogger.accounts.info("Cleared an isolated X session while retaining its local profile")
        } catch {
            modelContext.rollback()
            if storeWasDeleted {
                account.lastURLString = nil
            }
            _ = browserSession(for: account)
            KeaLogger.accounts.error("Failed to complete session clearing")
            errorMessage = storeWasDeleted
                ? "The X session was cleared, but Kea could not save the updated account metadata."
                : "Kea could not clear the local X session."
        }
    }

    func isSessionOperationInProgress(for accountID: UUID) -> Bool {
        sessionOperationAccountIDs.contains(accountID)
    }

    func browserSession(for account: AccountProfile) -> BrowserSession {
        webViewPool.session(
            for: account,
            restoreLastPage: preferences.restoreLastPage,
            hideXSidebar: preferences.hideXSidebar,
            openExternalLinks: { [weak self] in self?.preferences.openExternalLinks ?? true },
            onSafeURLChange: { [weak self, weak account] value in
                guard let self, let account else { return }
                account.lastURLString = value
                self.saveMetadata(reportUserError: false)
            }
        )
    }

    func reload() { webViewPool.reload(selectedAccountID) }
    func setXSidebarHidden(_ hidden: Bool) {
        preferences.hideXSidebar = hidden
        webViewPool.setXSidebarHidden(hidden)
    }
    func openHome(for account: AccountProfile) { webViewPool.openHome(account.id) }
    func open(_ destination: XDestination) { webViewPool.navigate(selectedAccountID, to: destination) }
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

    private func saveMetadata(reportUserError: Bool = true) {
        do {
            try modelContext.save()
        } catch {
            KeaLogger.app.error("Failed to persist local application metadata")
            if reportUserError {
                errorMessage = "Kea could not save that change."
            }
        }
    }

    private func cleanupOrphanedAvatars() {
        let identifiers = Set(accounts.compactMap(\.avatarIdentifier))
        do {
            try avatarStorage.cleanupOrphans(keeping: identifiers)
        } catch {
            KeaLogger.accounts.error("Failed to clean orphaned local avatar files")
        }
    }
}
