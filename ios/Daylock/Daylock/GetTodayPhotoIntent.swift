import AppIntents
import UniformTypeIdentifiers

enum DaylockIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noPhotos

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noPhotos:
            "Add at least one photo in Daylock first."
        }
    }
}

struct GetTodayPhotoIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Today's Daylock Photo"
    static var description = IntentDescription("Gets the photo Daylock scheduled for today, in the order you chose.")

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        guard
            let manifest = PhotoManifest.loadCurrent(),
            let today = manifest.scheduledPhoto(on: Date())
        else {
            throw DaylockIntentError.noPhotos
        }

        let url = today.record.fullImageURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw DaylockIntentError.noPhotos
        }

        let file = IntentFile(fileURL: url, filename: "Daylock-today.jpg", type: .jpeg)
        return .result(value: file)
    }
}

struct DaylockShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .orange

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetTodayPhotoIntent(),
            phrases: [
                "Get today's \(.applicationName) photo"
            ],
            shortTitle: "Today's Photo",
            systemImageName: "photo"
        )
    }
}
