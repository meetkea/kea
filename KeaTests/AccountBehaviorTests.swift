import XCTest
@testable import Kea

@MainActor
final class AccountBehaviorTests: XCTestCase {
    func testAccountOrderingUsesSortOrderThenCreationDate() {
        let now = Date()
        let later = now.addingTimeInterval(10)
        let second = AccountProfile(name: "Second", sortOrder: 1, createdAt: now)
        let laterFirst = AccountProfile(name: "Later first", sortOrder: 0, createdAt: later)
        let earlierFirst = AccountProfile(name: "Earlier first", sortOrder: 0, createdAt: now)

        XCTAssertEqual(
            AccountOrdering.sorted([second, laterFirst, earlierFirst]).map(\.name),
            ["Earlier first", "Later first", "Second"]
        )
    }

    func testRemovingSelectedMiddleAccountChoosesFollowingAccount() {
        let ids = [UUID(), UUID(), UUID()]
        XCTAssertEqual(
            AccountSelectionPolicy.replacementID(afterRemoving: ids[1], from: ids),
            ids[2]
        )
    }

    func testRemovingSelectedFirstAccountChoosesFollowingAccount() {
        let ids = [UUID(), UUID(), UUID()]
        XCTAssertEqual(
            AccountSelectionPolicy.replacementID(afterRemoving: ids[0], from: ids),
            ids[1]
        )
    }

    func testRemovingSelectedLastAccountChoosesPreviousAccount() {
        let ids = [UUID(), UUID(), UUID()]
        XCTAssertEqual(
            AccountSelectionPolicy.replacementID(afterRemoving: ids[2], from: ids),
            ids[1]
        )
    }

    func testRemovingOnlyAccountLeavesNoSelection() {
        let id = UUID()
        XCTAssertNil(AccountSelectionPolicy.replacementID(afterRemoving: id, from: [id]))
    }

    func testSelectedAccountIDPersists() throws {
        let suiteName = "KeaTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let expected = UUID()
        let first = AppPreferences(defaults: defaults)
        first.selectedAccountID = expected

        let restored = AppPreferences(defaults: defaults)
        XCTAssertEqual(restored.selectedAccountID, expected)
    }

    func testRelevantPreferencesPersist() throws {
        let suiteName = "KeaTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let first = AppPreferences(defaults: defaults)
        XCTAssertTrue(first.hideXSidebar)
        first.openLastAccount = false
        first.restoreLastPage = false
        first.openExternalLinks = false
        first.appearance = .dark
        first.showInMenuBar = false
        first.hideXSidebar = false

        let restored = AppPreferences(defaults: defaults)
        XCTAssertFalse(restored.openLastAccount)
        XCTAssertFalse(restored.restoreLastPage)
        XCTAssertFalse(restored.openExternalLinks)
        XCTAssertEqual(restored.appearance, .dark)
        XCTAssertFalse(restored.showInMenuBar)
        XCTAssertFalse(restored.hideXSidebar)
    }

    func testNewProfilesUseDifferentWebsiteDataStoreIdentifiers() {
        let first = AccountProfile(name: "Personal", sortOrder: 0)
        let second = AccountProfile(name: "Work", sortOrder: 1)
        XCTAssertNotEqual(first.dataStoreIdentifier, second.dataStoreIdentifier)
    }

    func testAccountShortcutsFollowVisibleOrderingAndStopAtNine() {
        let accounts = (0..<11).map { index in
            AccountProfile(name: "Account \(index)", sortOrder: 10 - index)
        }
        let ordered = AccountOrdering.sorted(accounts)
        let assignments = AccountShortcut.assignments(for: ordered)

        XCTAssertEqual(assignments.count, 9)
        XCTAssertEqual(assignments.map(\.accountID), Array(ordered.prefix(9)).map(\.id))
        XCTAssertEqual(assignments.map(\.number), Array(1...9))
    }
}
