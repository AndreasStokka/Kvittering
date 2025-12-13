import Foundation
import SwiftData

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var receiptCount: Int = 0
    @Published var recentReceipts: [Receipt] = []

    private var repository: ReceiptRepository?

    func attach(context: ModelContext) {
        repository = ReceiptRepository(context: context)
        refresh()
    }

    func refresh() {
        guard let repository else { return }
        let receipts = repository.fetchReceipts()
        receiptCount = receipts.count
        
        // Hent de 5 siste kvitteringene, sortert etter dato (nyeste først)
        recentReceipts = receipts
            .sorted { $0.purchaseDate > $1.purchaseDate }
            .prefix(5)
            .map { $0 }
    }
}
