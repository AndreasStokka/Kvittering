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
        let logPath = "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log"
        let logURL = URL(fileURLWithPath: logPath)
        
        // #region agent log
        Self.logger.debug("saveToPhotoLibrary called")
        let logData: [String: Any] = [
            "sessionId": "debug-session",
            "runId": "pre-fix",
            "hypothesisId": "H1",
            "location": "ImageStore.swift:50",
            "message": "saveToPhotoLibrary called",
            "data": [
                "imageSize": "\(image.size.width)x\(image.size.height)",
                "hasAlpha": (image.cgImage?.alphaInfo).map { "\($0.rawValue)" } ?? "unknown"
            ],
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: logData), let jsonString = String(data: jsonData, encoding: .utf8) {
            // Ensure directory exists
            let logDir = logURL.deletingLastPathComponent()
            _ = try? fileManager.createDirectory(at: logDir, withIntermediateDirectories: true)
            
            // Append to file
            if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                defer { try? fileHandle.close() }
                _ = try? fileHandle.seekToEnd()
                if let data = (jsonString + "\n").data(using: .utf8) {
                    _ = try? fileHandle.write(contentsOf: data)
                }
            } else {
                // File doesn't exist, create it
                _ = try? (jsonString + "\n").write(to: logURL, atomically: true, encoding: .utf8)
            }
        }
        // #endregion
        
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
        let alphaInfo = image.cgImage?.alphaInfo
        let alphaInfoValue = alphaInfo?.rawValue ?? 999
        Self.logger.debug("Alpha check - alphaInfo: \(alphaInfoValue)")
        
        // #region agent log
        let alphaCheckData: [String: Any] = [
            "sessionId": "debug-session",
            "runId": "pre-fix",
            "hypothesisId": "H2",
            "location": "ImageStore.swift:95",
            "message": "Alpha channel check",
            "data": [
                "alphaInfo": alphaInfo.map { "\($0.rawValue)" } ?? "nil"
            ],
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: alphaCheckData), let jsonString = String(data: jsonData, encoding: .utf8) {
            let logURL = URL(fileURLWithPath: logPath)
            if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                defer { try? fileHandle.close() }
                _ = try? fileHandle.seekToEnd()
                if let data = (jsonString + "\n").data(using: .utf8) {
                    _ = try? fileHandle.write(contentsOf: data)
                }
            } else {
                _ = try? (jsonString + "\n").write(to: logURL, atomically: true, encoding: .utf8)
            }
        }
        // #endregion
        
        // Alltid konverter bildet til RGB uten alpha-kanal for å unngå Photos framework-advarsel
        // Dette sikrer at bildet lagres uten alpha-kanal uavhengig av originalformat
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size, format: UIGraphicsImageRendererFormat.default())
        let imageWithoutAlpha = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        // #region agent log
        let newAlphaInfoValue = imageWithoutAlpha.cgImage?.alphaInfo.rawValue ?? 999
        Self.logger.debug("Image converted to remove alpha - new alphaInfo: \(newAlphaInfoValue)")
        let conversionData: [String: Any] = [
            "sessionId": "debug-session",
            "runId": "pre-fix",
            "hypothesisId": "H3",
            "location": "ImageStore.swift:125",
            "message": "Image converted to remove alpha",
            "data": [
                "originalAlphaInfo": alphaInfo.map { "\($0.rawValue)" } ?? "nil",
                "newAlphaInfo": (imageWithoutAlpha.cgImage?.alphaInfo).map { "\($0.rawValue)" } ?? "unknown"
            ],
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: conversionData), let jsonString = String(data: jsonData, encoding: .utf8) {
            let logURL = URL(fileURLWithPath: logPath)
            if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                defer { try? fileHandle.close() }
                _ = try? fileHandle.seekToEnd()
                if let data = (jsonString + "\n").data(using: .utf8) {
                    _ = try? fileHandle.write(contentsOf: data)
                }
            } else {
                _ = try? (jsonString + "\n").write(to: logURL, atomically: true, encoding: .utf8)
            }
        }
        // #endregion
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: imageWithoutAlpha)
        }
        
        // #region agent log
        Self.logger.debug("Image saved to photo library")
        let successData: [String: Any] = [
            "sessionId": "debug-session",
            "runId": "pre-fix",
            "hypothesisId": "H3",
            "location": "ImageStore.swift:147",
            "message": "Image saved to photo library",
            "data": [
                "finalAlphaInfo": (imageWithoutAlpha.cgImage?.alphaInfo).map { "\($0.rawValue)" } ?? "unknown"
            ],
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: successData), let jsonString = String(data: jsonData, encoding: .utf8) {
            let logURL = URL(fileURLWithPath: logPath)
            if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                defer { try? fileHandle.close() }
                _ = try? fileHandle.seekToEnd()
                if let data = (jsonString + "\n").data(using: .utf8) {
                    _ = try? fileHandle.write(contentsOf: data)
                }
            } else {
                try? (jsonString + "\n").write(to: logURL, atomically: true, encoding: .utf8)
            }
        }
        // #endregion
    }
}
