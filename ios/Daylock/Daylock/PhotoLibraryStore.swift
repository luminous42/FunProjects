import Foundation
import UIKit
import WidgetKit

@MainActor
final class PhotoLibraryStore: ObservableObject {
    @Published private(set) var manifest: PhotoManifest
    @Published private(set) var isImporting = false
    @Published private(set) var isSyncing = false
    @Published var statusMessage: String?
    private var needsAnotherSync = false

    private let root: URL
    private let photosDirectory: URL
    private let widgetDirectory: URL
    private let manifestURL: URL

    init() {
        root = AppGroup.prepareStorage()
        photosDirectory = root.appendingPathComponent("photos", isDirectory: true)
        widgetDirectory = root.appendingPathComponent("widget", isDirectory: true)
        manifestURL = root.appendingPathComponent("manifest.json")
        let calendar = Calendar.current
        manifest = ManifestStore.load(from: manifestURL) ?? PhotoManifest(
            anchorStartOfDay: calendar.startOfDay(for: Date()),
            albumLocalIdentifier: nil,
            photos: []
        )
    }

    var today: (record: PhotoRecord, position: Int)? {
        manifest.scheduledPhoto(on: Date())
    }

    var tomorrow: (record: PhotoRecord, position: Int)? {
        manifest.scheduledPhoto(on: DailySchedule.nextChange(after: Date()))
    }

    var albumIsCurrent: Bool {
        !manifest.photos.isEmpty && manifest.photos.allSatisfy { $0.assetLocalIdentifier != nil }
    }

    func thumbnail(for record: PhotoRecord) -> UIImage? {
        UIImage(contentsOfFile: record.widgetImageURL(root: root).path)
    }

    func fullImage(for record: PhotoRecord) -> UIImage? {
        UIImage(contentsOfFile: record.fullImageURL(root: root).path)
    }

    func add(images: [UIImage]) async {
        guard !images.isEmpty, !isImporting else { return }
        isImporting = true
        defer { isImporting = false }

        let wasEmpty = manifest.photos.isEmpty
        var added: [PhotoRecord] = []
        for image in images {
            guard
                let full = PhotoImageWriter.jpegData(from: image, maxPixel: 1600, quality: 0.86),
                let widget = PhotoImageWriter.jpegData(from: image, maxPixel: 700, quality: 0.8)
            else { continue }

            let id = UUID()
            let name = "\(id.uuidString).jpg"
            do {
                try full.write(to: photosDirectory.appendingPathComponent(name), options: .atomic)
                try widget.write(to: widgetDirectory.appendingPathComponent(name), options: .atomic)
                added.append(PhotoRecord(
                    id: id,
                    fileName: name,
                    widgetFileName: name,
                    assetLocalIdentifier: nil
                ))
            } catch {
                continue
            }
        }

        guard !added.isEmpty else {
            statusMessage = "Those photos could not be saved. Try choosing them again."
            return
        }

        if wasEmpty {
            manifest.anchorStartOfDay = Calendar.current.startOfDay(for: Date())
        }
        manifest.photos.append(contentsOf: added)
        persist()
        await syncAlbum()
    }

    func delete(_ record: PhotoRecord) async {
        manifest.photos.removeAll { $0.id == record.id }
        try? FileManager.default.removeItem(at: record.fullImageURL(root: root))
        try? FileManager.default.removeItem(at: record.widgetImageURL(root: root))
        persist()
        if let identifier = record.assetLocalIdentifier {
            await AlbumSyncService.deleteCopies(identifiers: [identifier])
        }
    }

    func delete(at offsets: IndexSet) async {
        let records = offsets.map { manifest.photos[$0] }
        for record in records {
            await delete(record)
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        var items = manifest.photos
        let moving = source.sorted().map { items[$0] }
        for index in source.sorted(by: >) {
            items.remove(at: index)
        }
        let insertAt = destination - source.filter { $0 < destination }.count
        let clamped = min(max(insertAt, 0), items.count)
        items.insert(contentsOf: moving, at: clamped)
        manifest.photos = items
        persist()
    }

    /// Makes the first photo in the current order the one shown today.
    func startOrderToday() {
        manifest.anchorStartOfDay = Calendar.current.startOfDay(for: Date())
        persist()
        statusMessage = "Today starts at the first photo. The next one appears at midnight."
    }

    func shiftAnchor(byDays days: Int) {
        guard let shifted = Calendar.current.date(byAdding: .day, value: days, to: manifest.anchorStartOfDay) else { return }
        manifest.anchorStartOfDay = Calendar.current.startOfDay(for: shifted)
        persist()
    }

    func syncAlbum() async {
        guard !manifest.photos.isEmpty else {
            statusMessage = "Choose at least one photo first."
            return
        }
        if isSyncing {
            needsAnotherSync = true
            return
        }
        isSyncing = true
        defer {
            isSyncing = false
            if needsAnotherSync {
                needsAnotherSync = false
                Task { await self.syncAlbum() }
            }
        }
        do {
            let synced = try await AlbumSyncService.sync(manifest: manifest, photosDirectory: photosDirectory)
            var orphans: [String] = []
            manifest.albumLocalIdentifier = synced.albumLocalIdentifier
            for photo in synced.photos {
                if let index = manifest.photos.firstIndex(where: { $0.id == photo.id }) {
                    manifest.photos[index].assetLocalIdentifier = photo.assetLocalIdentifier
                } else if let identifier = photo.assetLocalIdentifier {
                    orphans.append(identifier)
                }
            }
            persist()
            if !orphans.isEmpty {
                await AlbumSyncService.deleteCopies(identifiers: orphans)
            }
            let ready = manifest.photos.filter { $0.assetLocalIdentifier != nil }.count
            statusMessage = "The \(AppGroup.albumName) album has \(ready) photos."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func persist() {
        do {
            try ManifestStore.save(manifest, to: manifestURL)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            statusMessage = "Could not save your photos on this iPhone."
        }
    }
}

enum PhotoImageWriter {
    static func jpegData(from image: UIImage, maxPixel: CGFloat, quality: CGFloat) -> Data? {
        let rendered = render(image, maxPixel: maxPixel)
        return rendered.jpegData(compressionQuality: quality)
    }

    private static func render(_ image: UIImage, maxPixel: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        let ratio = longest > maxPixel && longest > 0 ? maxPixel / longest : 1
        let newSize = CGSize(
            width: max(1, floor(image.size.width * ratio)),
            height: max(1, floor(image.size.height * ratio))
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
