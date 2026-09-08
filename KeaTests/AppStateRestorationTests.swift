import SwiftData
import XCTest
@testable import Kea

@MainActor
final class AppStateRestorationTests: XCTestCase {
    func testRestoresRememberedSelectedAccount() throws {
        let container = try makeContainer()
        let first = AccountProfile(name: "Personal", sortOrder: 0)
        let second = AccountProfile(name: "Work", sortOrder: 1)
        container.mainContext.insert(first)
        container.mainContext.insert(second)
        try container.mainContext.save()

        let (preferences, defaults, suiteName) = try makePreferences()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        preferences.selectedAccountID = second.id

        let state = AppState(modelContext: container.mainContext, preferences: preferences)
        XCTAssertEqual(state.selectedAccountID, second.id)
    }

    func testInvalidRememberedSelectionFallsBackToFirstOrderedAccount() throws {
        let container = try makeContainer()
        let second = AccountProfile(name: "Second", sortOrder: 1)
        let first = AccountProfile(name: "First", sortOrder: 0)
        container.mainContext.insert(second)
        container.mainContext.insert(first)
        try container.mainContext.save()

        let (preferences, defaults, suiteName) = try makePreferences()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        preferences.selectedAccountID = UUID()

        let state = AppState(modelContext: container.mainContext, preferences: preferences)
        XCTAssertEqual(state.selectedAccountID, first.id)
        XCTAssertEqual(preferences.selectedAccountID, first.id)
    }

    func testOpenLastAccountPreferenceCanBeDisabled() throws {
        let container = try makeContainer()
        let first = AccountProfile(name: "First", sortOrder: 0)
        let second = AccountProfile(name: "Second", sortOrder: 1)
        container.mainContext.insert(first)
        container.mainContext.insert(second)
        try container.mainContext.save()

        let (preferences, defaults, suiteName) = try makePreferences()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        preferences.selectedAccountID = second.id
        preferences.openLastAccount = false

        let state = AppState(modelContext: container.mainContext, preferences: preferences)
        XCTAssertEqual(state.selectedAccountID, first.id)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([AccountProfile.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makePreferences() throws -> (AppPreferences, UserDefaults, String) {
        let suiteName = "KeaTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        return (AppPreferences(defaults: defaults), defaults, suiteName)
    }
}
