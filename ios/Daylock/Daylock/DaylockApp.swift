import SwiftUI

@main
struct DaylockApp: App {
    @StateObject private var store = PhotoLibraryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Theme.clayDeep)
                .preferredColorScheme(.light)
        }
    }
}
