import AppKit
import Foundation
import Observation
import WebKit

@MainActor
@Observable
final class BrowserState {
    var isLoading = false
    var canGoBack = false
    var canGoForward = false
    var errorMessage: String?
}

@MainActor
final class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    let state: BrowserState

    private let externalLinkService: ExternalLinkService
    private let openExternalLinks: () -> Bool
    private let onSafeURLChange: (String?) -> Void

    init(
        state: BrowserState,
        externalLinkService: ExternalLinkService,
        openExternalLinks: @escaping () -> Bool,
        onSafeURLChange: @escaping (String?) -> Void
    ) {
        self.state = state
        self.externalLinkService = externalLinkService
        self.openExternalLinks = openExternalLinks
        self.onSafeURLChange = onSafeURLChange
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
        state.isLoading = true
        state.errorMessage = nil
        updateNavigationState(for: webView)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {
        state.isLoading = true
        updateNavigationState(for: webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        state.isLoading = false
        state.errorMessage = nil
        updateNavigationState(for: webView)
        onSafeURLChange(SafeXURL.persistedString(from: webView.url))
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation?,
        withError error: Error
    ) {
        report(error, webView: webView)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {
        report(error, webView: webView)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        KeaLogger.webView.notice("An account web process terminated; reloading only the affected view")
        state.errorMessage = nil
        state.isLoading = true

        if webView.url != nil {
            webView.reload()
        } else {
            webView.load(URLRequest(url: SafeXURL.home))
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        if externalLinkService.shouldOpenExternally(
            navigationAction,
            preferenceEnabled: openExternalLinks()
        ), let url = navigationAction.request.url {
            externalLinkService.open(url)
            return .cancel
        }
        return .allow
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil,
              let url = navigationAction.request.url
        else {
            return nil
        }

        if externalLinkService.shouldOpenExternally(
            navigationAction,
            preferenceEnabled: openExternalLinks()
        ) {
            externalLinkService.open(url)
        } else {
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable ([URL]?) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = parameters.allowsMultipleSelection
        panel.canChooseDirectories = parameters.allowsDirectories
        panel.canChooseFiles = true
        panel.begin { response in
            completionHandler(response == .OK ? panel.urls : nil)
        }
    }

    private func updateNavigationState(for webView: WKWebView) {
        state.canGoBack = webView.canGoBack
        state.canGoForward = webView.canGoForward
    }

    private func report(_ error: Error, webView: WKWebView) {
        state.isLoading = false
        updateNavigationState(for: webView)

        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled { return }

        KeaLogger.webView.error("A web navigation failed with code \(nsError.code, privacy: .public)")
        if BrowserFailurePolicy.shouldShowNativeOverlay(for: nsError) {
            state.errorMessage = "Unable to load X\n\nCheck your connection and try again."
        }
    }
}
