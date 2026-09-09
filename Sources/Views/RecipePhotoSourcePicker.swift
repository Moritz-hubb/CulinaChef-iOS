import SwiftUI
import PhotosUI
import UIKit

struct RecipePhotoSourceButton<Label: View>: View {
    let onPicked: (Data) -> Void
    @ViewBuilder let label: () -> Label

    @State private var showSourcePicker = false
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var selectedPhoto: PhotosPickerItem?

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        Button {
            showSourcePicker = true
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .confirmationDialog(L.common_chooseImage.localized, isPresented: $showSourcePicker, titleVisibility: .visible) {
            if cameraAvailable {
                Button(L.common_takePhoto.localized) {
                    showCamera = true
                }
            }
            Button(L.common_chooseFromGallery.localized) {
                showGallery = true
            }
            Button(L.cancel.localized, role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(isPresented: $showCamera, sourceType: .camera, onPicked: onPicked)
        }
        .photosPicker(isPresented: $showGallery, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                guard let item = newValue,
                      let data = try? await item.loadTransferable(type: Data.self) else { return }
                await MainActor.run {
                    selectedPhoto = nil
                    onPicked(data)
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var sourceType: UIImagePickerController.SourceType = .camera
    var onPicked: (Data) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        if !isPresented {
            uiViewController.dismiss(animated: true)
        }
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.isPresented = false
            if let img = info[.originalImage] as? UIImage, let data = img.jpegData(compressionQuality: 0.85) {
                parent.onPicked(data)
            }
        }
    }
}
