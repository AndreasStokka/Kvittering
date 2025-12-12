import SwiftUI
import PhotosUI
import VisionKit

struct NewReceiptOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showScanner = false
    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var presentEditor = false

    var body: some View {
        NavigationStack {
            List {
                Button("Skann med kamera") { showScanner = true }
                Button("Velg fra Bilder") { showPhotoPicker = true }
                Button("Legg inn kvittering manuelt") { presentEditor = true }
            }
            .navigationTitle("Ny kvittering")
            .sheet(isPresented: $presentEditor) {
                EditReceiptView(sourceImage: selectedImage)
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(image: $selectedImage)
                    .onDisappear { presentEditor = selectedImage != nil }
            }
            .sheet(isPresented: $showScanner) {
                DocumentScanner(image: $selectedImage)
                    .onDisappear { presentEditor = selectedImage != nil }
            }
        }
    }
}
