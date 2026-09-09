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
        hideXSidebar: Bool,
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
        configuration.userContentController.addUserScript(WKUserScript(
            source: XPresentationStyle.script(hideRightSidebar: hideXSidebar),
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        ))
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
        KeaLogger.sessions.info("Created one isolated web view for an account")
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
        KeaLogger.sessions.info("Released an account web view")
    }

    func deleteSession(for account: AccountProfile) async throws {
        release(accountID: account.id)
        // BrowserPane retains only a weak WKWebView reference. Removing the
        // view from its host and then from this pool releases WebKit's owner
        // before the persistent store is deleted.
        await Task.yield()
        try await sessionManager.deleteDataStore(for: account.dataStoreIdentifier)
        KeaLogger.sessions.info("Deleted an isolated persistent website data store")
    }

    func reload(_ accountID: UUID?) {
        existingSession(for: accountID)?.webView.reload()
    }

    func setXSidebarHidden(_ hidden: Bool) {
        let script = XPresentationStyle.script(hideRightSidebar: hidden)
        for session in sessions.values {
            session.webView.evaluateJavaScript(script) { _, _ in }
        }
    }

    func openHome(_ accountID: UUID?) {
        navigate(accountID, to: .home)
    }

    func navigate(_ accountID: UUID?, to destination: XDestination) {
        existingSession(for: accountID)?.webView.load(URLRequest(url: destination.url))
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
