import XCTest
@testable import Kea

final class BrowserFailurePolicyTests: XCTestCase {
    func testShowsNativeOverlayForOfflineFailure() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        XCTAssertTrue(BrowserFailurePolicy.shouldShowNativeOverlay(for: error))
    }

    func testDoesNotReplaceOrdinaryNonConnectivityFailure() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse)
        XCTAssertFalse(BrowserFailurePolicy.shouldShowNativeOverlay(for: error))
    }

    func testIgnoresUnrelatedErrorDomains() {
        let error = NSError(domain: "KeaTests", code: NSURLErrorNotConnectedToInternet)
        XCTAssertFalse(BrowserFailurePolicy.shouldShowNativeOverlay(for: error))
    }
}
