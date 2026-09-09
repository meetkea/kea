import AppKit
import SwiftData
import XCTest
@testable import Kea

@MainActor
final class AccountCustomizationTests: XCTestCase {
    func testAccentAndAvatarIdentifiersPersist() throws {
        let container = try makeContainer()
        let account = AccountProfile(name: "Personal", sortOrder: 0)
        account.accentIdentifier = AccountAccent.purple.storedIdentifier
        account.avatarIdentifier = "avatar.png"
        container.mainContext.insert(account)
        try container.mainContext.save()

        let fetched = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<AccountProfile>()).first)
        XCTAssertEqual(fetched.accentIdentifier, "purple")
        XCTAssertEqual(fetched.avatarIdentifier, "avatar.png")
        XCTAssertEqual(fetched.dataStoreIdentifier, account.dataStoreIdentifier)
    }

    func testReplacingAvatarUpdatesMetadataAndDeletesPreviousCopy() throws {
        let resources = try makeResources()
        defer { try? FileManager.default.removeItem(at: resources.directory) }
        let account = AccountProfile(name: "Work", sortOrder: 0)
        resources.container.mainContext.insert(account)
        try resources.container.mainContext.save()
        let state = AppState(
            modelContext: resources.container.mainContext,
            preferences: resources.preferences,
            avatarStorage: resources.storage
        )

        let firstSource = resources.directory.appending(path: "first.png")
        let secondSource = resources.directory.appending(path: "second.png")
        try writeTestImage(color: .systemBlue, to: firstSource)
        try writeTestImage(color: .systemPink, to: secondSource)

        state.replaceAvatar(for: account, with: firstSource)
        let firstIdentifier = try XCTUnwrap(account.avatarIdentifier)
        XCTAssertTrue(resources.storage.contains(firstIdentifier))

        state.replaceAvatar(for: account, with: secondSource)
        let secondIdentifier = try XCTUnwrap(account.avatarIdentifier)
        XCTAssertNotEqual(firstIdentifier, secondIdentifier)
        XCTAssertFalse(resources.storage.contains(firstIdentifier))
        XCTAssertTrue(resources.storage.contains(secondIdentifier))
    }

    func testRemovingAccountDeletesOnlyKeaOwnedAvatarCopy() async throws {
        let resources = try makeResources()
        defer { try? FileManager.default.removeItem(at: resources.directory) }
        let account = AccountProfile(name: "Recern", sortOrder: 0)
        resources.container.mainContext.insert(account)
        try resources.container.mainContext.save()
        let state = AppState(
            modelContext: resources.container.mainContext,
            preferences: resources.preferences,
            avatarStorage: resources.storage
        )

        let source = resources.directory.appending(path: "source.png")
        try writeTestImage(color: .systemGreen, to: source)
        state.replaceAvatar(for: account, with: source)
        let identifier = try XCTUnwrap(account.avatarIdentifier)

        await state.remove(account)

        XCTAssertFalse(resources.storage.contains(identifier))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(state.accounts.isEmpty)
    }

    func testRemovingCustomAvatarClearsMetadataAndDeletesCopy() throws {
        let resources = try makeResources()
        defer { try? FileManager.default.removeItem(at: resources.directory) }
        let account = AccountProfile(name: "Personal", sortOrder: 0)
        resources.container.mainContext.insert(account)
        try resources.container.mainContext.save()
        let state = AppState(
            modelContext: resources.container.mainContext,
            preferences: resources.preferences,
            avatarStorage: resources.storage
        )
        let source = resources.directory.appending(path: "source.png")
        try writeTestImage(color: .systemTeal, to: source)
        state.replaceAvatar(for: account, with: source)
        let identifier = try XCTUnwrap(account.avatarIdentifier)

        state.removeCustomAvatar(from: account)

        XCTAssertNil(account.avatarIdentifier)
        XCTAssertFalse(resources.storage.contains(identifier))
    }

    func testNormalizedAvatarIsRetinaReadySquarePNG() throws {
        let resources = try makeResources()
        defer { try? FileManager.default.removeItem(at: resources.directory) }
        let source = resources.directory.appending(path: "wide.png")
        try writeTestImage(color: .systemOrange, size: NSSize(width: 600, height: 300), to: source)

        let identifier = try resources.storage.saveAvatar(from: source)
        let image = try XCTUnwrap(resources.storage.image(for: identifier))
        let representation = try XCTUnwrap(image.representations.first)
        XCTAssertEqual(representation.pixelsWide, AvatarStorage.pixelSize)
        XCTAssertEqual(representation.pixelsHigh, AvatarStorage.pixelSize)
    }

    func testOrphanCleanupPreservesReferencedAvatar() throws {
        let resources = try makeResources()
        defer { try? FileManager.default.removeItem(at: resources.directory) }
        let source = resources.directory.appending(path: "source.png")
        try writeTestImage(color: .systemPurple, to: source)
        let referenced = try resources.storage.saveAvatar(from: source)
        let orphaned = try resources.storage.saveAvatar(from: source)

        try resources.storage.cleanupOrphans(keeping: [referenced])

        XCTAssertTrue(resources.storage.contains(referenced))
        XCTAssertFalse(resources.storage.contains(orphaned))
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([AccountProfile.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeResources() throws -> (
        directory: URL,
        container: ModelContainer,
        preferences: AppPreferences,
        storage: AvatarStorage
    ) {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "KeaTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let suiteName = "KeaTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return (
            directory,
            try makeContainer(),
            AppPreferences(defaults: defaults),
            AvatarStorage(baseDirectory: directory)
        )
    }

    private func writeTestImage(
        color: NSColor,
        size: NSSize = NSSize(width: 400, height: 300),
        to url: URL
    ) throws {
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        let data = try XCTUnwrap(
            image.tiffRepresentation
                .flatMap(NSBitmapImageRep.init(data:))?
                .representation(using: .png, properties: [:])
        )
        try data.write(to: url)
    }
}
