import AppKit
import Foundation
import WebKit

@MainActor
struct ExternalLinkService {
    private let embeddedAuthenticationHosts = Set([
        "accounts.google.com",
        "appleid.apple.com"
    ])

    func shouldOpenExternally(_ action: WKNavigationAction, preferenceEnabled: Bool) -> Bool {
        guard preferenceEnabled,
              action.navigationType == .linkActivated,
              let url = action.request.url,
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              !SafeXURL.isXHost(url.host),
              !isEmbeddedAuthenticationHost(url.host)
        else {
            return false
        }
        return true
    }

    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    private func isEmbeddedAuthenticationHost(_ host: String?) -> Bool {
        guard let host else { return false }
        return embeddedAuthenticationHosts.contains(host.lowercased())
    }
}
