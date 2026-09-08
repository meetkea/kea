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
}
