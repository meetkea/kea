import Foundation
import WebKit

@MainActor
final class AccountSessionManager {
    typealias DataStoreRemoval = @MainActor (UUID) async throws -> Void

    private let removeDataStore: DataStoreRemoval
    private let retryDelays: [Duration]

    init(
        retryDelays: [Duration] = [
            .milliseconds(100),
            .milliseconds(250),
            .milliseconds(500),
            .seconds(1)
        ],
        removeDataStore: @escaping DataStoreRemoval = { identifier in
            try await WKWebsiteDataStore.remove(forIdentifier: identifier)
        }
    ) {
        self.retryDelays = retryDelays
        self.removeDataStore = removeDataStore
    }

    func dataStore(for identifier: UUID) -> WKWebsiteDataStore {
        WKWebsiteDataStore(forIdentifier: identifier)
    }

    func deleteDataStore(for identifier: UUID) async throws {
        for attempt in 0...retryDelays.count {
            do {
                try await removeDataStore(identifier)
                return
            } catch {
                guard attempt < retryDelays.count else { throw error }
                try await Task.sleep(for: retryDelays[attempt])
            }
        }
    }
}
