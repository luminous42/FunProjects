import Foundation

/// Shared container for the app and the home screen widget.
/// The same identifier must appear in both entitlements files.
enum AppGroup {
    static let identifier = "group.com.luminous42.daylock"
    static let albumName = "Daylock"
    static let urlScheme = "daylock"

    static func storageRoot() -> URL {
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) {
            return container
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return documents.appendingPathComponent("Daylock", isDirectory: true)
    }

    static var usesSharedContainer: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil
    }

    @discardableResult
    static func prepareStorage() -> URL {
        let root = storageRoot()
        let fileManager = FileManager.default
        try? fileManager.createDirectory(
            at: root.appendingPathComponent("photos", isDirectory: true),
            withIntermediateDirectories: true
        )
        try? fileManager.createDirectory(
            at: root.appendingPathComponent("widget", isDirectory: true),
            withIntermediateDirectories: true
        )
        return root
    }
}
