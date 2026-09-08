import XCTest
@testable import Kea

final class SafeXURLTests: XCTestCase {
    func testAcceptsExpectedXDestinations() throws {
        let values = [
            "https://x.com/home",
            "https://x.com/notifications",
            "https://x.com/messages",
            "https://x.com/i/bookmarks",
            "https://x.com/meetkea",
            "https://x.com/meetkea/status/123456789"
        ]

        for value in values {
            XCTAssertEqual(SafeXURL.persistedString(from: try XCTUnwrap(URL(string: value))), value)
            XCTAssertEqual(SafeXURL.restorableURL(from: value).absoluteString, value)
        }
    }

    func testKeepsSafeXPathAndDropsNonSensitiveQueryAndFragment() {
        let input = URL(string: "https://x.com/search?q=kea#fragment")
        XCTAssertEqual(SafeXURL.persistedString(from: input), "https://x.com/search")
    }

    func testRejectsAuthenticationAndSecurityPaths() {
        let values = [
            "https://x.com/i/flow/login",
            "https://x.com/i/flow/password_reset",
            "https://x.com/i/oauth2/authorize",
            "https://x.com/callback",
            "https://x.com/reset",
            "https://x.com/settings",
            "https://x.com/settings/password",
            "https://x.com/account/access"
        ]

        for value in values {
            XCTAssertNil(SafeXURL.persistedString(from: URL(string: value)))
            XCTAssertEqual(SafeXURL.restorableURL(from: value), SafeXURL.home)
        }
    }

    func testRejectsTemporaryCredentialParameters() {
        let values = [
            "https://x.com/home?code=temporary",
            "https://x.com/home?oauth_token=temporary",
            "https://x.com/home?state=temporary",
            "https://x.com/home?token=temporary"
        ]

        for value in values {
            XCTAssertNil(SafeXURL.persistedString(from: URL(string: value)))
            XCTAssertEqual(SafeXURL.restorableURL(from: value), SafeXURL.home)
        }
    }

    func testRejectsNonXHost() {
        XCTAssertNil(SafeXURL.persistedString(from: URL(string: "https://example.com/home")))
    }

    func testMalformedStoredURLFallsBackToHome() {
        XCTAssertEqual(SafeXURL.restorableURL(from: "not a url"), SafeXURL.home)
    }
}
