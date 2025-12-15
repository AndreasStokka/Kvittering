import Foundation
import UIKit

struct ImageStore {
    private let fileManager = FileManager.default

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
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("ReceiptImages")
    }
}
