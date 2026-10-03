import Foundation

struct PhotoRecord: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var fileName: String
    var widgetFileName: String
    /// Asset created inside the Daylock album. This is a copy, not the original photo.
    var assetLocalIdentifier: String?

    func widgetImageURL(root: URL = AppGroup.storageRoot()) -> URL {
        root
            .appendingPathComponent("widget", isDirectory: true)
            .appendingPathComponent(widgetFileName)
    }

    func fullImageURL(root: URL = AppGroup.storageRoot()) -> URL {
        root
            .appendingPathComponent("photos", isDirectory: true)
            .appendingPathComponent(fileName)
    }
}

struct PhotoManifest: Codable, Equatable, Sendable {
    var anchorStartOfDay: Date
    var albumLocalIdentifier: String?
    var photos: [PhotoRecord]

    func scheduledPhoto(on date: Date, calendar: Calendar = .current) -> (record: PhotoRecord, position: Int)? {
        guard !photos.isEmpty else { return nil }
        let index = DailySchedule.index(
            for: date,
            count: photos.count,
            anchor: anchorStartOfDay,
            calendar: calendar
        )
        return (photos[index], index + 1)
    }

    static var fileURL: URL {
        AppGroup.storageRoot().appendingPathComponent("manifest.json")
    }

    static func loadCurrent() -> PhotoManifest? {
        ManifestStore.load(from: fileURL)
    }
}

enum ManifestStore {
    static func load(from url: URL) -> PhotoManifest? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(PhotoManifest.self, from: data)
    }

    static func save(_ manifest: PhotoManifest, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(manifest)
        try data.write(to: url, options: .atomic)
    }
}
