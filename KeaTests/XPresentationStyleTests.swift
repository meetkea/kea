import XCTest
@testable import Kea

@MainActor
final class XPresentationStyleTests: XCTestCase {
    func testHiddenStyleTargetsOnlyXLayoutColumns() {
        let script = XPresentationStyle.script(hideRightSidebar: true)

        XCTAssertTrue(script.contains("[data-testid=\"sidebarColumn\"]"))
        XCTAssertTrue(script.contains("[data-testid=\"primaryColumn\"]"))
        XCTAssertTrue(script.contains("classList.toggle('kea-hide-x-sidebar', true)"))
        XCTAssertFalse(script.contains("password"))
        XCTAssertFalse(script.contains("input"))
    }

    func testVisibleStyleRemovesThePresentationClass() {
        let script = XPresentationStyle.script(hideRightSidebar: false)

        XCTAssertTrue(script.contains("classList.toggle('kea-hide-x-sidebar', false)"))
    }
}
