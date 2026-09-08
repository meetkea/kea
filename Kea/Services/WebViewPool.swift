import Foundation
import Observation
import WebKit

@MainActor
@Observable
final class BrowserSession {
    let accountID: UUID
    let webView: WKWebView
    let state: BrowserState

    fileprivate let coordinator: WebViewCoordinator

    init(
        accountID: UUID,
        webView: WKWebView,
        state: BrowserState,
        coordinator: WebViewCoordinator
    ) {
        self.accountID = accountID
        self.webView = webView
        self.state = state
        self.coordinator = coordinator
    }
}

@MainActor
@Observable
final class WebViewPool {
    private(set) var sessions: [UUID: BrowserSession] = [:]

    private let sessionManager: AccountSessionManager
    private let externalLinkService = ExternalLinkService()

    init(sessionManager: AccountSessionManager = AccountSessionManager()) {
        self.sessionManager = sessionManager
    }

    func session(
        for account: AccountProfile,
        restoreLastPage: Bool,
        openExternalLinks: @escaping () -> Bool,
        onSafeURLChange: @escaping (String?) -> Void
    ) -> BrowserSession {
        if let existing = sessions[account.id] {
            return existing
        }

        let state = BrowserState()
        let coordinator = WebViewCoordinator(
            state: state,
            externalLinkService: externalLinkService,
            openExternalLinks: openExternalLinks,
            onSafeURLChange: onSafeURLChange
        )
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = sessionManager.dataStore(for: account.dataStoreIdentifier)
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        webView.allowsMagnification = true

        let initialURL = restoreLastPage
            ? SafeXURL.restorableURL(from: account.lastURLString)
            : SafeXURL.home
        webView.load(URLRequest(url: initialURL))

        let session = BrowserSession(
            accountID: account.id,
            webView: webView,
            state: state,
            coordinator: coordinator
        )
        sessions[account.id] = session
        return session
    }

    func existingSession(for accountID: UUID?) -> BrowserSession? {
        guard let accountID else { return nil }
        return sessions[accountID]
    }

    func release(accountID: UUID) {
        guard let session = sessions.removeValue(forKey: accountID) else { return }
        session.webView.stopLoading()
        session.webView.navigationDelegate = nil
        session.webView.uiDelegate = nil
        session.webView.removeFromSuperview()
    }

    func deleteSession(for account: AccountProfile) async throws {
        release(accountID: account.id)
        await Task.yield()
        try await sessionManager.deleteDataStore(for: account.dataStoreIdentifier)
    }

    func reload(_ accountID: UUID?) {
        existingSession(for: accountID)?.webView.reload()
    }

    func openHome(_ accountID: UUID?) {
        existingSession(for: accountID)?.webView.load(URLRequest(url: SafeXURL.home))
    }

    func goBack(_ accountID: UUID?) {
        existingSession(for: accountID)?.webView.goBack()
    }

    func goForward(_ accountID: UUID?) {
        existingSession(for: accountID)?.webView.goForward()
    }

    func zoom(_ accountID: UUID?, delta: Double) {
        guard let webView = existingSession(for: accountID)?.webView else { return }
        webView.pageZoom = min(max(webView.pageZoom + delta, 0.5), 3)
    }

    func actualSize(_ accountID: UUID?) {
        existingSession(for: accountID)?.webView.pageZoom = 1
    }
}
