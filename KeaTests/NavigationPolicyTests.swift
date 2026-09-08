import XCTest
@testable import Kea

final class NavigationPolicyTests: XCTestCase {
    func testKeepsXNavigationInAccount() {
        XCTAssertEqual(
            disposition(destination: "https://x.com/notifications", source: "https://x.com/home"),
            .allowInAccount
        )
    }

    func testOpensOrdinaryExternalLinkFromTimelineExternally() {
        XCTAssertEqual(
            disposition(destination: "https://example.com/article", source: "https://x.com/home"),
            .openExternally
        )
    }

    func testKeepsUnknownAuthenticationProviderInAccount() {
        XCTAssertEqual(
            disposition(destination: "https://identity.example/sign-in", source: "https://x.com/i/flow/login"),
            .allowInAccount
        )
    }

    func testKeepsAuthenticationRedirectsInAccount() {
        XCTAssertEqual(
            disposition(
                destination: "https://callback.example/continue",
                source: "https://identity.example/sign-in",
                isUserInitiated: false
            ),
            .allowInAccount
        )
    }

    func testExternalLinkPreferenceCanKeepNavigationInAccount() {
        XCTAssertEqual(
            disposition(
                destination: "https://example.com/article",
                source: "https://x.com/home",
                openExternalLinks: false
            ),
            .allowInAccount
        )
    }

    private func disposition(
        destination: String,
        source: String,
        isUserInitiated: Bool = true,
        openExternalLinks: Bool = true
    ) -> NavigationDisposition {
        NavigationPolicy.disposition(
            destinationURL: URL(string: destination),
            sourceURL: URL(string: source),
            isUserInitiated: isUserInitiated,
            openExternalLinks: openExternalLinks
        )
    }
}
