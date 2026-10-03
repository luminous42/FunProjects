import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: PhotoLibraryStore
    @State private var showPicker = false
    @State private var showOrder = false
    @State private var selected: PhotoRecord?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            PaperScreen {
                Group {
                    if store.manifest.photos.isEmpty {
                        empty
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(store.manifest.photos) { photo in
                                    Button {
                                        selected = photo
                                    } label: {
                                        PhotoThumb(
                                            image: store.thumbnail(for: photo),
                                            isToday: photo.id == store.today?.record.id
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(accessibilityLabel(for: photo))
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !store.manifest.photos.isEmpty {
                        Button("Order") { showOrder = true }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPicker = true
                    } label: {
                        Label("Choose Photos", systemImage: "plus")
                    }
                }
            }
            .photoPickSheet(isPresented: $showPicker)
            .sheet(isPresented: $showOrder) {
                OrderSheet()
            }
            .fullScreenCover(item: $selected) { photo in
                PhotoDetail(photo: photo)
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 14) {
            Spacer()
            Text("No photos yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text("Choose a few from your gallery. They stay in this order, one each day.")
                .font(.body)
                .foregroundStyle(Theme.ink.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Choose Photos") { showPicker = true }
                .buttonStyle(ClayButtonStyle())
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func accessibilityLabel(for photo: PhotoRecord) -> String {
        let index = (store.manifest.photos.firstIndex(where: { $0.id == photo.id }) ?? 0) + 1
        let today = photo.id == store.today?.record.id ? ", today's photo" : ""
        return "Photo \(index) of \(store.manifest.photos.count)\(today)"
    }
}

private struct PhotoThumb: View {
    var image: UIImage?
    var isToday: Bool

    var body: some View {
        Color.clear
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .overlay { thumb }
            .overlay(alignment: .topLeading) {
                if isToday {
                    Text("Today")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.card, in: Capsule())
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var thumb: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Theme.line
        }
    }
}

private struct PhotoDetail: View {
    @EnvironmentObject private var store: PhotoLibraryStore
    @Environment(\.dismiss) private var dismiss
    var photo: PhotoRecord

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ink.ignoresSafeArea()
                if let image = store.fullImage(for: photo) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Remove", role: .destructive) {
                        Task {
                            await store.delete(photo)
                            dismiss()
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

private struct OrderSheet: View {
    @EnvironmentObject private var store: PhotoLibraryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("The first photo is the start of the cycle. Daylock advances one photo every midnight.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
                Section {
                    ForEach(Array(store.manifest.photos.enumerated()), id: \.element.id) { index, photo in
                        HStack(spacing: 12) {
                            if let image = store.thumbnail(for: photo) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Photo \(index + 1)")
                                if photo.id == store.today?.record.id {
                                    Text("Today")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Theme.clayDeep)
                                }
                            }
                        }
                    }
                    .onMove { source, destination in
                        store.move(from: source, to: destination)
                    }
                    .onDelete { offsets in
                        Task { await store.delete(at: offsets) }
                    }
                }
                Section {
                    Button("Start this order today") {
                        store.startOrderToday()
                    }
                    #if DEBUG
                    Button("Pretend it's tomorrow") {
                        store.shiftAnchor(byDays: -1)
                    }
                    #endif
                }
            }
            .navigationTitle("Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
