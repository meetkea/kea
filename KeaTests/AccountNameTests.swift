import XCTest
@testable import Kea

final class AccountNameTests: XCTestCase {
    func testTrimsLocalAccountName() {
        XCTAssertEqual(AccountName.normalized("  Personal \n"), "Personal")
    }

    func testRejectsEmptyLocalAccountName() {
        XCTAssertNil(AccountName.normalized("  \n\t "))
    }
}
