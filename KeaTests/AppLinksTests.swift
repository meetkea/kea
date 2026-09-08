import XCTest
@testable import Kea

@MainActor
final class AppLinksTests: XCTestCase {
    func testSupportURLIsThePublicKeaSupportPage() {
        XCTAssertEqual(AppLinks.support.absoluteString, "https://usekea.com/support")
    }
}
