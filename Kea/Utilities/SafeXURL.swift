import Foundation

enum SafeXURL {
    nonisolated static let home = URL(string: "https://x.com/home")!

    nonisolated private static let allowedHosts = Set([
        "x.com", "www.x.com", "twitter.com", "www.twitter.com"
    ])

    nonisolated private static let sensitivePrefixes = [
        "/i/flow/login",
        "/i/flow/signup",
        "/i/oauth2",
        "/account/access",
        "/settings/security",
        "/settings/password"
    ]

    nonisolated static func restorableURL(from value: String?) -> URL {
        guard let value, let url = URL(string: value), isSafe(url) else {
            return home
        }
        return sanitized(url) ?? home
    }

    nonisolated static func persistedString(from url: URL?) -> String? {
        guard let url, isSafe(url) else { return nil }
        return sanitized(url)?.absoluteString
    }

    nonisolated static func isXHost(_ host: String?) -> Bool {
        guard let host else { return false }
        return allowedHosts.contains(host.lowercased())
    }

    nonisolated private static func isSafe(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https", isXHost(url.host), url.user == nil, url.password == nil else {
            return false
        }

        let path = url.path.lowercased()
        return !sensitivePrefixes.contains { path.hasPrefix($0) }
    }

    nonisolated private static func sanitized(_ url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.query = nil
        components.fragment = nil
        return components.url
    }
}
