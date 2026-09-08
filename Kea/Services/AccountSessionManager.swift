import Foundation
import WebKit

@MainActor
final class AccountSessionManager {
    func dataStore(for identifier: UUID) -> WKWebsiteDataStore {
        WKWebsiteDataStore(forIdentifier: identifier)
    }

    func deleteDataStore(for identifier: UUID) async throws {
        try await WKWebsiteDataStore.remove(forIdentifier: identifier)
    }
}
