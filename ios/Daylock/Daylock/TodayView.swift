import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: PhotoLibraryStore
    @Binding var tab: Int
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            PaperScreen {
                ScrollView {
                    VStack(spacing: 22) {
                        if let today = store.today {
                            LockScreenPreview(
                                image: store.fullImage(for: today.record),
                                position: today.position,
                                total: store.manifest.photos.count
                            )
                            scheduleCard(today: today)
                            if !store.albumIsCurrent {
                                setupPrompt
                            }
                            if let statusMessage = store.statusMessage {
                                Text(statusMessage)
                                    .font(.footnote)
                                    .foregroundStyle(Theme.ink.opacity(0.65))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPicker = true
                    } label: {
                        Label("Choose Photos", systemImage: "plus")
                    }
                }
            }
            .photoPickSheet(isPresented: $showPicker)
        }
    }

    private func scheduleCard(today: (record: PhotoRecord, position: Int)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photo \(today.position) of \(store.manifest.photos.count)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text(scheduleDetail)
                .font(.body)
                .foregroundStyle(Theme.ink.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
            if let tomorrow = store.tomorrow, store.manifest.photos.count > 1 {
                HStack(spacing: 12) {
                    if let image = store.thumbnail(for: tomorrow.record) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    Text("Tomorrow is photo \(tomorrow.position).")
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink.opacity(0.72))
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var scheduleDetail: String {
        if store.manifest.photos.count == 1 {
            return "This is the only photo on the schedule. Add more and Daylock will move to the next one at midnight."
        }
        return "Your library plays in order. At midnight this phone switches to the next photo."
    }

    private var setupPrompt: some View {
        Button {
            tab = 2
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.clayDeep)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Put these on the lock screen")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text("One setup in Settings keeps them rotating every day.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.ink.opacity(0.4))
            }
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.clay)
                .padding(.top, 36)
            Text("Choose the photos for your lock screen")
                .font(.system(.title2, design: .serif))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("Daylock shows a different one each day. You pick the set. A one-time Photo Shuffle setup tells iOS to use it on the lock screen.")
                .font(.body)
                .foregroundStyle(Theme.ink.opacity(0.72))
                .multilineTextAlignment(.center)
            Button("Choose Photos") {
                showPicker = true
            }
            .buttonStyle(ClayButtonStyle())
            .padding(.top, 4)
        }
        .padding(.horizontal, 8)
    }
}

struct LockScreenPreview: View {
    var image: UIImage?
    var position: Int
    var total: Int

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Color.clear
                .overlay {
                    photoBackground
                }
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.45), .black.opacity(0.05), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
                .overlay(alignment: .top) {
                    VStack(spacing: 2) {
                        Text(context.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .tracking(1.3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .padding(.horizontal, 20)
                        Text(context.date.formatted(.dateTime.hour().minute()))
                            .font(.system(size: 64, weight: .light, design: .rounded))
                            .monospacedDigit()
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
                    .padding(.top, 36)
                }
                .overlay(alignment: .bottom) {
                    Text("\(position) of \(total)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.35), in: Capsule())
                        .padding(.bottom, 18)
                }
                .clipped()
        }
        .aspectRatio(9.0 / 16.0, contentMode: .fit)
        .frame(maxWidth: 320)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Theme.ink.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 22, y: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lock screen preview, photo \(position) of \(total)")
    }

    @ViewBuilder
    private var photoBackground: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Theme.ink
        }
    }
}

#Preview {
    TodayView(tab: .constant(0))
        .environmentObject(PhotoLibraryStore())
        .preferredColorScheme(.light)
}
