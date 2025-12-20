import Foundation
import UIKit
import Photos
import os.log

struct ImageStore {
    private let fileManager = FileManager.default
    private static let logger = Logger(subsystem: "com.example.Kvittering", category: "ImageStore")

    func saveImage(_ image: UIImage, id: UUID) throws -> String {
        let url = try imageURL(for: id)
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "ImageStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kunne ikke konvertere bilde"])
        }
        try data.write(to: url, options: .atomic)
        return url.lastPathComponent
    }

    func loadImage(path: String) -> UIImage? {
        let url = directoryURL().appendingPathComponent(path)
        return UIImage(contentsOfFile: url.path)
    }

    func deleteImage(path: String?) {
        guard let path else { return }
        let url = directoryURL().appendingPathComponent(path)
        try? fileManager.removeItem(at: url)
    }
    
    /// Get the file URL for an image path
    func imageFileURL(path: String) -> URL? {
        let url = directoryURL().appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return url
    }

    private func imageURL(for id: UUID) throws -> URL {
        let dir = directoryURL()
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("\(id.uuidString).jpg")
    }

    private func directoryURL() -> URL {
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            // Fallback til temp directory hvis documents directory ikke finnes
            return fileManager.temporaryDirectory.appendingPathComponent("ReceiptImages")
        }
        return docs.appendingPathComponent("ReceiptImages")
    }
    
    /// Lagrer bilde til fotobiblioteket
    /// - Parameter image: Bildet som skal lagres
    func saveToPhotoLibrary(_ image: UIImage) async throws {
        Self.logger.debug("saveToPhotoLibrary called")
        
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        
        guard status == .authorized || status == .limited else {
            throw NSError(
                domain: "ImageStore",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Tilgang til fotobiblioteket ble ikke gitt"]
            )
        }
        
        // Konverter bildet til et format uten alpha-kanal for å unngå unødvendig filstørrelse
        // Vi konverterer alltid bildet for å sikre at det ikke har alpha-kanal, selv om det ser ut til å være opakt
        let alphaInfoValue = image.cgImage?.alphaInfo.rawValue ?? 999
        Self.logger.debug("Alpha check - alphaInfo: \(alphaInfoValue)")
        
        // Alltid konverter bildet til RGB uten alpha-kanal for å unngå Photos framework-advarsel
        // Dette sikrer at bildet lagres uten alpha-kanal uavhengig av originalformat
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size, format: UIGraphicsImageRendererFormat.default())
        let imageWithoutAlpha = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        let newAlphaInfoValue = imageWithoutAlpha.cgImage?.alphaInfo.rawValue ?? 999
        Self.logger.debug("Image converted to remove alpha - new alphaInfo: \(newAlphaInfoValue)")
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: imageWithoutAlpha)
        }
        
        Self.logger.debug("Image saved to photo library")
    }
}
