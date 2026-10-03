import SwiftUI
import UIKit

struct GuideView: View {
    @EnvironmentObject private var store: PhotoLibraryStore
    @State private var copied = false

    var body: some View {
        NavigationStack {
            PaperScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your photos, a different one each day.")
                            .font(.system(.title2, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Text("iPhone doesn't let an app change the lock screen wallpaper by itself. Daylock keeps an album of the photos you chose. After you point Photo Shuffle at that album once, iOS changes the lock screen every day.")
                            .font(.body)
                            .foregroundStyle(Theme.ink.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)

                        step(number: "1", title: "Choose photos") {
                            Text("Add them from the Today or Library tab. Reorder them anytime. The Today tab follows that order, one photo per day.")
                        }

                        step(number: "2", title: "Update the Daylock album") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Daylock saves copies into a Photos album named \(AppGroup.albumName). Your originals stay put. Removing a photo here deletes only the copy. The next update also takes other photos out of that album so the lock screen stays on the ones you picked.")
                                Button {
                                    Task { await store.syncAlbum() }
                                } label: {
                                    Text(store.isSyncing ? "Updating…" : "Update Album")
                                }
                                .buttonStyle(ClayButtonStyle())
                                .disabled(store.isSyncing || store.manifest.photos.isEmpty)
                                .opacity(store.manifest.photos.isEmpty ? 0.45 : 1)
                                Button {
                                    UIPasteboard.general.string = AppGroup.albumName
                                    copied = true
                                } label: {
                                    Label(copied ? "Copied" : "Copy album name", systemImage: "doc.on.doc")
                                        .font(.subheadline.weight(.medium))
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(Theme.clayDeep)
                            }
                        }

                        step(number: "3", title: "Turn on Photo Shuffle") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Do this once:")
                                pathLine("Settings")
                                pathLine("Wallpaper")
                                pathLine("Add New Wallpaper")
                                pathLine("Photo Shuffle")
                                pathLine("Album → \(AppGroup.albumName)")
                                pathLine("Frequency → Daily")
                                pathLine("Set as Lock Screen")
                                Text("You can also long-press the lock screen, tap +, and choose Photo Shuffle.")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.ink.opacity(0.6))
                                    .padding(.top, 4)
                            }
                        }

                        noticeCard(
                            title: "What changes automatically",
                            body: "Photo Shuffle picks from the Daylock album and changes it on the daily frequency you set. It does not follow your custom order. The Today tab and the home screen widget do follow that order, and they change at midnight."
                        )

                        noticeCard(
                            title: "Home screen widget",
                            body: "Touch and hold the Home Screen, tap +, and add Daylock. It shows today's scheduled photo in color. Lock Screen widgets can't show a full-color photo, so Daylock's lock screen widget shows the photo number instead."
                        )

                        noticeCard(
                            title: "Exact photo, via Shortcuts",
                            body: "If you want today's exact photo, not a shuffle: in Shortcuts, make a Time of Day automation. Add Get Today's Daylock Photo, then Set Wallpaper, and choose Lock Screen. iOS may ask you to confirm before it changes the wallpaper."
                        )

                        if !AppGroup.usesSharedContainer {
                            noticeCard(
                                title: "Widget storage isn't shared yet",
                                body: "Select your Development Team for both targets, and keep the App Group \(AppGroup.identifier) on the app and the widget. Until that group is available, the home screen widget can't see your photos."
                            )
                        }

                        if let statusMessage = store.statusMessage {
                            Text(statusMessage)
                                .font(.subheadline)
                                .foregroundStyle(Theme.ink.opacity(0.75))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if store.albumIsCurrent {
                            Label("Album matches your library", systemImage: "checkmark.circle.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.clayDeep)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Lock Screen")
        }
    }

    private func step<Content: View>(number: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(number)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.card)
                    .frame(width: 26, height: 26)
                    .background(Theme.ink, in: Circle())
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
            }
            content()
                .font(.subheadline)
                .foregroundStyle(Theme.ink.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func pathLine(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Theme.clay)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.ink)
        }
    }

    private func noticeCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(Theme.ink.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
