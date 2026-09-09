import XCTest
@testable import Kea

@MainActor
final class AccountSessionManagerTests: XCTestCase {
    func testDeleteRetriesWhileWebKitFinishesReleasingTheStore() async throws {
        var attempts = 0
        let manager = AccountSessionManager(retryDelays: [.zero, .zero]) { _ in
            attempts += 1
            if attempts < 3 {
                throw TestRemovalError.storeStillInUse
            }
        }

        try await manager.deleteDataStore(for: UUID())

        XCTAssertEqual(attempts, 3)
    }

    func testDeleteStopsAfterTheBoundedRetrySchedule() async {
        var attempts = 0
        let manager = AccountSessionManager(retryDelays: [.zero, .zero]) { _ in
            attempts += 1
            throw TestRemovalError.storeStillInUse
        }

        do {
            try await manager.deleteDataStore(for: UUID())
            XCTFail("Expected removal to fail after the retry schedule")
        } catch {
            XCTAssertEqual(error as? TestRemovalError, .storeStillInUse)
        }

        XCTAssertEqual(attempts, 3)
    }
}

private enum TestRemovalError: Error {
    case storeStillInUse
}
