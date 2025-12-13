import Foundation
import SwiftData

@MainActor
final class SettingsViewModel: ObservableObject {
    private var repository: ReceiptRepository?

    init() {
        // Repository vil bli satt i attach()
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
