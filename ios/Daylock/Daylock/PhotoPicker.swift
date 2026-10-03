import PhotosUI
import SwiftUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onPick: ([UIImage]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0
        configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoPicker

        init(parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            guard !results.isEmpty else { return }
            let providers = results.map(\.itemProvider)
            Task {
                var images: [UIImage] = []
                for provider in providers {
                    if let image = await Self.loadImage(from: provider) {
                        images.append(image)
                    }
                }
                let deliver = parent.onPick
                await MainActor.run {
                    deliver(images)
                }
            }
        }

        private static func loadImage(from provider: NSItemProvider) async -> UIImage? {
            guard provider.canLoadObject(ofClass: UIImage.self) else { return nil }
            return await withCheckedContinuation { continuation in
                let lock = NSLock()
                var resumed = false
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    lock.lock()
                    defer { lock.unlock() }
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume(returning: object as? UIImage)
                }
            }
        }
    }
}

struct PhotoPickSheet: ViewModifier {
    @EnvironmentObject private var store: PhotoLibraryStore
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            PhotoPicker(isPresented: $isPresented) { images in
                Task { await store.add(images: images) }
            }
        }
    }
}

extension View {
    func photoPickSheet(isPresented: Binding<Bool>) -> some View {
        modifier(PhotoPickSheet(isPresented: isPresented))
    }
}
