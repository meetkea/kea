import XCTest
@testable import Kea

final class PasskeyAccessPolicyTests: XCTestCase {
    func testOnlyNotDeterminedStateCanRequestAccess() {
        XCTAssertTrue(PasskeyAccessPolicy.canRequestAccess(status: .notDetermined, isRequesting: false))
        XCTAssertFalse(PasskeyAccessPolicy.canRequestAccess(status: .authorized, isRequesting: false))
        XCTAssertFalse(PasskeyAccessPolicy.canRequestAccess(status: .denied, isRequesting: false))
    }

    func testConcurrentRequestIsPrevented() {
        XCTAssertFalse(PasskeyAccessPolicy.canRequestAccess(status: .notDetermined, isRequesting: true))
    }
}
