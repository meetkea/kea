import SwiftData
import XCTest
@testable import Kea

@MainActor
final class CommandPaletteTests: XCTestCase {
    func testCommandFilteringMatchesAccountAndActionSubstrings() {
        let account = AccountProfile(name: "Recern", sortOrder: 0)
        let items = CommandPaletteCatalog.items(
            accounts: [account],
            hasActiveSession: true,
            canGoBack: false,
            canGoForward: false
        )

        XCTAssertEqual(CommandPaletteCatalog.filtered(items, query: "rec").map(\.title), ["Recern"])
        XCTAssertEqual(
            CommandPaletteCatalog.filtered(items, query: "notif").map(\.title),
            ["Open Notifications"]
        )
        XCTAssertEqual(CommandPaletteCatalog.filtered(items, query: "set").map(\.title), ["Settings"])
    }

    func testAccountSelectionClosesPaletteWithoutCreatingWebView() throws {
        let schema = Schema([AccountProfile.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let first = AccountProfile(name: "Personal", sortOrder: 0)
        let second = AccountProfile(name: "Work", sortOrder: 1)
        container.mainContext.insert(first)
        container.mainContext.insert(second)
        try container.mainContext.save()
        let state = AppState(modelContext: container.mainContext)
        state.isCommandPalettePresented = true
        let sessionsBefore = state.webViewPool.sessions.count

        state.selectAccountFromCommandPalette(second.id)

        XCTAssertEqual(state.selectedAccountID, second.id)
        XCTAssertFalse(state.isCommandPalettePresented)
        XCTAssertEqual(state.webViewPool.sessions.count, sessionsBefore)
    }

    func testPaletteHidesBrowserActionsWithoutActiveSession() {
        let items = CommandPaletteCatalog.items(
            accounts: [],
            hasActiveSession: false,
            canGoBack: false,
            canGoForward: false
        )

        XCTAssertFalse(items.contains { $0.command == .reload })
        XCTAssertFalse(items.contains { $0.command == .open(.home) })
        XCTAssertTrue(items.contains { $0.command == .addAccount })
        XCTAssertTrue(items.contains { $0.command == .settings })
    }
}
