import SwiftUI
import PhotosUI

struct PhotoPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    @State private var selection: PhotosPickerItem?
    
    /// Maks dimensjon (bredde/høyde) for nedskalering
    private let maxDimension: CGFloat = 2048

    var body: some View {
        PhotosPicker("Velg bilde", selection: $selection, matching: .images)
            .onChange(of: selection) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self), 
                       let uiImage = UIImage(data: data) {
                        let resized = downsample(uiImage, maxDimension: maxDimension)
                        await MainActor.run { 
                            image = resized 
                            dismiss()
                        }
                    }
                }
            }
    }
    
    /// Nedskalerer bildet hvis det overskrider maxDimension
    private func downsample(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        
        guard maxSide > maxDimension else { return image }
        
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
