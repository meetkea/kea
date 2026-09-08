import Foundation

nonisolated enum NavigationDisposition: Equatable, Sendable {
    case allowInAccount
    case openExternally
}

enum NavigationPolicy {
    nonisolated static func disposition(
        destinationURL: URL?,
        sourceURL: URL?,
        isUserInitiated: Bool,
        openExternalLinks: Bool
    ) -> NavigationDisposition {
        guard openExternalLinks,
              isUserInitiated,
              let destinationURL,
              ["http", "https"].contains(destinationURL.scheme?.lowercased() ?? ""),
              !SafeXURL.isXHost(destinationURL.host),
              !isAuthenticationContext(sourceURL)
        else {
            return .allowInAccount
        }

        return .openExternally
    }

    nonisolated private static func isAuthenticationContext(_ url: URL?) -> Bool {
        guard let url else { return true }

        // Once an authentication flow has left x.com, keep its redirects and
        // provider pages in the same isolated account instead of guessing hosts.
        guard SafeXURL.isXHost(url.host) else { return true }

        let path = url.path.lowercased()
        return path == "/"
            || path.hasPrefix("/i/flow/")
            || path.hasPrefix("/login")
            || path.hasPrefix("/signup")
            || path.hasPrefix("/oauth")
    }
}
