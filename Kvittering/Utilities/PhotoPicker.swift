import SwiftUI
import PhotosUI

struct PhotoPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    @State private var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker("Velg bilde", selection: $selection, matching: .images)
            .onChange(of: selection) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                        await MainActor.run { 
                            image = uiImage 
                            dismiss()
                        }
                    }
                }
            }
    }
}
