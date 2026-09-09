import SwiftData
import XCTest
@testable import Kea

@MainActor
final class AccountLimitTests: XCTestCase {
    func testAccountCreationIsAllowedWithZeroThroughFourAccounts() throws {
        for existingCount in 0..<AccountLimit.maximumAccountCount {
            let resources = try makeState(existingCount: existingCount)
            defer { resources.defaults.removePersistentDomain(forName: resources.suiteName) }

            resources.state.addAccount(named: "New Account")

            XCTAssertEqual(resources.state.accounts.count, existingCount + 1)
        }
    }

    func testFifthAccountCanBeCreated() throws {
        let resources = try makeState(existingCount: 4)
        defer { resources.defaults.removePersistentDomain(forName: resources.suiteName) }

        resources.state.addAccount(named: "Fifth")

        XCTAssertEqual(resources.state.accounts.count, AccountLimit.maximumAccountCount)
        XCTAssertTrue(resources.state.accounts.contains { $0.name == "Fifth" })
    }

    func testSixthAccountIsRejected() throws {
        let resources = try makeState(existingCount: AccountLimit.maximumAccountCount)
        defer { resources.defaults.removePersistentDomain(forName: resources.suiteName) }

        resources.state.addAccount(named: "Sixth")

        XCTAssertEqual(resources.state.accounts.count, AccountLimit.maximumAccountCount)
        XCTAssertFalse(resources.state.accounts.contains { $0.name == "Sixth" })
        XCTAssertEqual(resources.state.errorTitle, AccountLimit.alertTitle)
        XCTAssertEqual(resources.state.errorMessage, AccountLimit.alertMessage)
    }

    func testExistingFiveAccountsRemainUntouched() throws {
        let resources = try makeState(existingCount: AccountLimit.maximumAccountCount)
        defer { resources.defaults.removePersistentDomain(forName: resources.suiteName) }
        let identifiers = resources.state.accounts.map(\.id)

        resources.state.requestAddAccount()

        XCTAssertEqual(resources.state.accounts.map(\.id), identifiers)
        XCTAssertFalse(resources.state.isPresentingAddAccount)
    }

    func testExistingDataAboveTheLimitIsNotDeleted() throws {
        let resources = try makeState(existingCount: AccountLimit.maximumAccountCount + 2)
        defer { resources.defaults.removePersistentDomain(forName: resources.suiteName) }
        let identifiers = resources.state.accounts.map(\.id)

        resources.state.requestAddAccount()

        XCTAssertEqual(resources.state.accounts.map(\.id), identifiers)
        XCTAssertEqual(resources.state.accounts.count, AccountLimit.maximumAccountCount + 2)
    }

    func testRemovalBelowTheLimitAllowsAddingAgain() async throws {
        let resources = try makeState(existingCount: AccountLimit.maximumAccountCount)
        defer { resources.defaults.removePersistentDomain(forName: resources.suiteName) }
        let account = try XCTUnwrap(resources.state.accounts.last)

        await resources.state.remove(account)
        XCTAssertTrue(resources.state.canAddAccount)

        resources.state.addAccount(named: "Replacement")

        XCTAssertEqual(resources.state.accounts.count, AccountLimit.maximumAccountCount)
        XCTAssertTrue(resources.state.accounts.contains { $0.name == "Replacement" })
    }

    private func makeState(existingCount: Int) throws -> LimitTestResources {
        let schema = Schema([AccountProfile.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        for index in 0..<existingCount {
            container.mainContext.insert(AccountProfile(name: "Account \(index + 1)", sortOrder: index))
        }
        try container.mainContext.save()

        let suiteName = "KeaTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let preferences = AppPreferences(defaults: defaults)
        let state = AppState(modelContext: container.mainContext, preferences: preferences)
        return LimitTestResources(
            container: container,
            state: state,
            defaults: defaults,
            suiteName: suiteName
        )
    }
}

@MainActor
private final class LimitTestResources {
    let container: ModelContainer
    let state: AppState
    let defaults: UserDefaults
    let suiteName: String

    init(
        container: ModelContainer,
        state: AppState,
        defaults: UserDefaults,
        suiteName: String
    ) {
        self.container = container
        self.state = state
        self.defaults = defaults
        self.suiteName = suiteName
    }
}
