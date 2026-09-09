import AppKit
import Foundation
import UniformTypeIdentifiers

enum AvatarStorageError: LocalizedError {
    case unreadableImage
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .unreadableImage: "The selected file could not be opened as an image."
        case .imageEncodingFailed: "The selected image could not be prepared."
        }
    }
}

@MainActor
final class AvatarStorage {
    static let pixelSize = 256

    private let directoryURL: URL
    private var imageCache: [String: NSImage] = [:]

    init(baseDirectory: URL? = nil) {
        let applicationSupport = baseDirectory ?? FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appending(path: "Kea", directoryHint: .isDirectory)
        directoryURL = applicationSupport.appending(path: "Avatars", directoryHint: .isDirectory)
    }

    func saveAvatar(from sourceURL: URL) throws -> String {
        let accessedSecurityScopedResource = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessedSecurityScopedResource {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard let sourceImage = NSImage(contentsOf: sourceURL) else {
            throw AvatarStorageError.unreadableImage
        }
        let data = try Self.normalizedPNGData(from: sourceImage)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let identifier = "\(UUID().uuidString).png"
        try data.write(to: fileURL(for: identifier), options: .atomic)
        imageCache[identifier] = NSImage(data: data)
        return identifier
    }

    func image(for identifier: String?) -> NSImage? {
        guard let identifier, isValid(identifier) else { return nil }
        if let cached = imageCache[identifier] {
            return cached
        }
        guard let image = NSImage(contentsOf: fileURL(for: identifier)) else { return nil }
        imageCache[identifier] = image
        return image
    }

    func deleteAvatar(_ identifier: String?) throws {
        guard let identifier, isValid(identifier) else { return }
        imageCache.removeValue(forKey: identifier)
        let url = fileURL(for: identifier)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    func cleanupOrphans(keeping identifiers: Set<String>) throws {
        guard FileManager.default.fileExists(atPath: directoryURL.path) else { return }
        let files = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        for file in files where file.pathExtension.lowercased() == "png" {
            guard !identifiers.contains(file.lastPathComponent) else { continue }
            imageCache.removeValue(forKey: file.lastPathComponent)
            try FileManager.default.removeItem(at: file)
        }
    }

    func contains(_ identifier: String?) -> Bool {
        guard let identifier, isValid(identifier) else { return false }
        return FileManager.default.fileExists(atPath: fileURL(for: identifier).path)
    }

    private func fileURL(for identifier: String) -> URL {
        directoryURL.appending(path: identifier, directoryHint: .notDirectory)
    }

    private func isValid(_ identifier: String) -> Bool {
        (identifier as NSString).lastPathComponent == identifier
            && identifier.hasSuffix(".png")
    }

    private static func normalizedPNGData(from sourceImage: NSImage) throws -> Data {
        let sourceSize = sourceImage.size
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            throw AvatarStorageError.unreadableImage
        }

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelSize,
            pixelsHigh: pixelSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            throw AvatarStorageError.imageEncodingFailed
        }

        let targetSize = NSSize(width: pixelSize, height: pixelSize)
        let scale = max(targetSize.width / sourceSize.width, targetSize.height / sourceSize.height)
        let drawSize = NSSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        let drawRect = NSRect(
            x: (targetSize.width - drawSize.width) / 2,
            y: (targetSize.height - drawSize.height) / 2,
            width: drawSize.width,
            height: drawSize.height
        )

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        sourceImage.draw(
            in: drawRect,
            from: NSRect(origin: .zero, size: sourceSize),
            operation: .copy,
            fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw AvatarStorageError.imageEncodingFailed
        }
        return data
    }
}

@MainActor
enum AvatarPicker {
    static func chooseImage() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose Account Avatar"
        panel.prompt = "Choose Avatar"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .heic, .webP]
        return panel.runModal() == .OK ? panel.url : nil
    }
}
