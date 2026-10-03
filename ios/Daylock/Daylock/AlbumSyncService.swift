import Photos
import UIKit

enum AlbumSyncError: LocalizedError {
    case denied
    case failed

    var errorDescription: String? {
        switch self {
        case .denied:
            "Photo access is off. Daylock can still show today's photo here and in the widget. To put the photos on the lock screen, allow photo access and update the album."
        case .failed:
            "The Daylock album could not be updated."
        }
    }
}

/// Copies chosen photos into a Photos album named Daylock.
/// iOS Photo Shuffle reads that album. Originals are left where they are.
enum AlbumSyncService {
    static func sync(manifest: PhotoManifest, photosDirectory: URL) async throws -> PhotoManifest {
        try await requireReadWriteAccess()
        var updated = manifest
        let albumID = try await ensureAlbum(existingID: updated.albumLocalIdentifier)
        updated.albumLocalIdentifier = albumID

        for index in updated.photos.indices {
            if let identifier = updated.photos[index].assetLocalIdentifier,
               PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).count > 0 {
                continue
            }
            let fileURL = photosDirectory.appendingPathComponent(updated.photos[index].fileName)
            guard let image = UIImage(contentsOfFile: fileURL.path) else { continue }
            if let assetID = try? await addImage(image, toAlbum: albumID) {
                updated.photos[index].assetLocalIdentifier = assetID
            }
        }

        let linked = updated.photos.compactMap(\.assetLocalIdentifier)
        if linked.count == updated.photos.count {
            try? await removeUnmanagedAssets(fromAlbum: albumID, keeping: Set(linked))
        }
        return updated
    }

    static func deleteCopies(identifiers: [String]) async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else { return }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        guard assets.count > 0 else { return }
        var copies: [PHAsset] = []
        assets.enumerateObjects { asset, _, _ in
            copies.append(asset)
        }
        try? await perform {
            PHAssetChangeRequest.deleteAssets(copies as NSArray)
        }
    }

    private static func requireReadWriteAccess() async throws {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        let status: PHAuthorizationStatus
        if current == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        } else {
            status = current
        }
        guard status == .authorized || status == .limited else {
            throw AlbumSyncError.denied
        }
    }

    private static func ensureAlbum(existingID: String?) async throws -> String {
        if let existingID {
            let existing = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [existingID],
                options: nil
            )
            if let album = existing.firstObject {
                return album.localIdentifier
            }
        }

        let named = PHFetchOptions()
        named.predicate = NSPredicate(format: "title = %@", AppGroup.albumName)
        let byTitle = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: named)
        if let album = byTitle.firstObject {
            return album.localIdentifier
        }

        let box = IDBox()
        try await perform {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: AppGroup.albumName)
            box.value = request.placeholderForCreatedAssetCollection.localIdentifier
        }
        guard let created = box.value else { throw AlbumSyncError.failed }
        return created
    }

    private static func addImage(_ image: UIImage, toAlbum albumID: String) async throws -> String {
        let box = IDBox()
        try await perform {
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            guard let placeholder = request.placeholderForCreatedAsset else { return }
            box.value = placeholder.localIdentifier
            guard
                let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumID], options: nil).firstObject,
                let change = PHAssetCollectionChangeRequest(for: album)
            else { return }
            change.addAssets([placeholder] as NSArray)
        }
        guard let created = box.value else { throw AlbumSyncError.failed }
        return created
    }

    private static func removeUnmanagedAssets(fromAlbum albumID: String, keeping owned: Set<String>) async throws {
        guard
            let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumID], options: nil).firstObject
        else { return }

        let contents = PHAsset.fetchAssets(in: album, options: nil)
        var extras: [PHAsset] = []
        contents.enumerateObjects { asset, _, _ in
            if !owned.contains(asset.localIdentifier) {
                extras.append(asset)
            }
        }
        guard !extras.isEmpty else { return }

        try await perform {
            guard
                let fresh = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumID], options: nil).firstObject,
                let change = PHAssetCollectionChangeRequest(for: fresh)
            else { return }
            change.removeAssets(extras as NSArray)
        }
    }

    private static func perform(_ changes: @escaping () -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges(changes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: AlbumSyncError.failed)
                }
            }
        }
    }
}

private final class IDBox: @unchecked Sendable {
    var value: String?
}
