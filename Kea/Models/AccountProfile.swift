import Foundation
import SwiftData

@Model
final class AccountProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var dataStoreIdentifier: UUID
    var sortOrder: Int
    var createdAt: Date
    var lastOpenedAt: Date?
    var lastURLString: String?
    var accentIdentifier: String?

    init(
        id: UUID = UUID(),
        name: String,
        dataStoreIdentifier: UUID = UUID(),
        sortOrder: Int,
        createdAt: Date = Date(),
        lastOpenedAt: Date? = nil,
        lastURLString: String? = nil,
        accentIdentifier: String? = nil
    ) {
        self.id = id
        self.name = name
        self.dataStoreIdentifier = dataStoreIdentifier
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.lastOpenedAt = lastOpenedAt
        self.lastURLString = lastURLString
        self.accentIdentifier = accentIdentifier
    }
}

enum AccountOrdering {
    static func sorted(_ accounts: [AccountProfile]) -> [AccountProfile] {
        accounts.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.createdAt < $1.createdAt
            }
            return $0.sortOrder < $1.sortOrder
        }
    }
}

enum AccountSelectionPolicy {
    static func replacementID(
        afterRemoving removedID: UUID,
        from orderedIDs: [UUID]
    ) -> UUID? {
        guard let removedIndex = orderedIDs.firstIndex(of: removedID) else {
            return orderedIDs.first
        }

        let remaining = orderedIDs.filter { $0 != removedID }
        guard !remaining.isEmpty else { return nil }
        return remaining[min(removedIndex, remaining.count - 1)]
    }
}
