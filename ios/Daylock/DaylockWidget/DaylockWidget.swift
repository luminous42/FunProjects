import SwiftUI
import WidgetKit

struct PhotoEntry: TimelineEntry {
    let date: Date
    let imagePath: String?
    let position: Int
    let total: Int
}

struct TodayPhotoProvider: TimelineProvider {
    func placeholder(in context: Context) -> PhotoEntry {
        PhotoEntry(date: Date(), imagePath: nil, position: 1, total: 1)
    }

    func getSnapshot(in context: Context, completion: @escaping (PhotoEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PhotoEntry>) -> Void) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        var entries: [PhotoEntry] = []
        for offset in 0..<8 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            entries.append(entry(for: offset == 0 ? Date() : day))
        }
        let refresh = calendar.date(byAdding: .day, value: 8, to: start) ?? Date().addingTimeInterval(8 * 86_400)
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    private func entry(for date: Date) -> PhotoEntry {
        guard
            let manifest = PhotoManifest.loadCurrent(),
            let scheduled = manifest.scheduledPhoto(on: date)
        else {
            return PhotoEntry(date: date, imagePath: nil, position: 0, total: 0)
        }
        return PhotoEntry(
            date: date,
            imagePath: scheduled.record.widgetImageURL().path,
            position: scheduled.position,
            total: manifest.photos.count
        )
    }
}

struct TodayPhotoWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: PhotoEntry

    var body: some View {
        let showPhoto = family == .systemSmall || family == .systemMedium
        content
            .widgetURL(URL(string: "\(AppGroup.urlScheme)://today"))
            .containerBackground(for: .widget) {
                if showPhoto {
                    WidgetPhoto(path: entry.imagePath)
                } else {
                    AccessoryWidgetBackground()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        default:
            home
        }
    }

    private var home: some View {
        VStack {
            Spacer(minLength: 0)
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.58)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                HStack {
                    Text(entry.total == 0 ? "Add photos" : "Today")
                    Spacer()
                    if entry.total > 0 {
                        Text("\(entry.position) of \(entry.total)")
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .padding(12)
            }
            .frame(height: 72)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var circular: some View {
        VStack(spacing: 0) {
            if entry.total == 0 {
                Image(systemName: "photo")
            } else {
                Text("\(entry.position)")
                    .font(.headline.weight(.semibold))
                Text("of \(entry.total)")
                    .font(.caption2)
            }
        }
        .padding(4)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Daylock")
                .font(.headline)
            Text(entry.total == 0 ? "Add photos" : "Photo \(entry.position) of \(entry.total)")
                .font(.caption)
            Text("Changes at midnight")
                .font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

struct WidgetPhoto: View {
    var path: String?

    var body: some View {
        if let path, let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color(red: 0.110, green: 0.098, blue: 0.082)
        }
    }
}

struct TodayPhotoWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayPhoto", provider: TodayPhotoProvider()) { entry in
            TodayPhotoWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Photo")
        .description("Shows the photo Daylock scheduled for today.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
        .contentMarginsDisabled()
    }
}

@main
struct DaylockWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayPhotoWidget()
    }
}
