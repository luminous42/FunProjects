import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: PhotoLibraryStore
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            TodayView(tab: $tab)
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(0)
            LibraryView()
                .tabItem { Label("Library", systemImage: "photo.on.rectangle") }
                .tag(1)
            GuideView()
                .tabItem { Label("Lock Screen", systemImage: "lock") }
                .tag(2)
        }
        .onOpenURL { _ in
            tab = 0
        }
        .overlay(alignment: .bottom) {
            if store.isImporting || store.isSyncing {
                statusPill
                    .padding(.bottom, 64)
            }
        }
    }

    private var statusPill: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(store.isImporting ? "Adding photos" : "Updating album")
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
