import XCTest
@testable import Kea

final class SafeXURLTests: XCTestCase {
    func testKeepsSafeXPathAndDropsQueryAndFragment() {
        let input = URL(string: "https://x.com/home?utm_source=test#fragment")
        XCTAssertEqual(SafeXURL.persistedString(from: input), "https://x.com/home")
    }

    func testRejectsLoginFlow() {
        XCTAssertNil(SafeXURL.persistedString(from: URL(string: "https://x.com/i/flow/login?token=secret")))
    }

    func testRejectsNonXHost() {
        XCTAssertNil(SafeXURL.persistedString(from: URL(string: "https://example.com/home")))
    }

    func testMalformedStoredURLFallsBackToHome() {
        XCTAssertEqual(SafeXURL.restorableURL(from: "not a url"), SafeXURL.home)
    }
}
