import Foundation
import SwiftData

@MainActor
final class SettingsViewModel: ObservableObject {
    private var repository: ReceiptRepository?
    
    private let saveToPhotoLibraryKey = "saveReceiptsToPhotoLibrary"
    
    @Published var saveToPhotoLibrary: Bool {
        didSet {
            UserDefaults.standard.set(saveToPhotoLibrary, forKey: saveToPhotoLibraryKey)
        }
    }

    init() {
        // Repository vil bli satt i attach()
        self.saveToPhotoLibrary = UserDefaults.standard.bool(forKey: saveToPhotoLibraryKey)
    }

    func attach(context: ModelContext) {
        repository = ReceiptRepository(context: context)
    }

    func deleteAll() throws {
        guard let repository else {
            throw NSError(domain: "SettingsViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ModelContext er ikke tilkoblet"])
        }
        try repository.deleteAll()
    }
}
