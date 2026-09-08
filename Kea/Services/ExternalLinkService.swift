import AppKit
import Foundation
import WebKit

@MainActor
struct ExternalLinkService {
    func shouldOpenExternally(_ action: WKNavigationAction, preferenceEnabled: Bool) -> Bool {
        NavigationPolicy.disposition(
            destinationURL: action.request.url,
            sourceURL: action.sourceFrame.request.url,
            isUserInitiated: action.navigationType == .linkActivated,
            openExternalLinks: preferenceEnabled
        ) == .openExternally
    }

    func open(_ url: URL) {
        KeaLogger.webView.info("Opening a user-initiated external link in the default browser")
        NSWorkspace.shared.open(url)
    }
}
