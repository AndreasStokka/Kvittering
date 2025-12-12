import Foundation
import SwiftData

@MainActor
final class SettingsViewModel: ObservableObject {
    private var repository: ReceiptRepository?

    init(context: ModelContext) {
        repository = ReceiptRepository(context: context)
    }

    func attach(context: ModelContext) {
        repository = ReceiptRepository(context: context)
    }

    func deleteAll() throws {
        try repository?.deleteAll()
    }
}
