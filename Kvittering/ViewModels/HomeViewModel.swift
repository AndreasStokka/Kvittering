import Foundation
import SwiftData

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var receiptCount: Int = 0
    @Published var lastCategorySummary: [String: Int] = [:]
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
        var summary: [String: Int] = [:]
        for receipt in receipts {
            summary[receipt.category, default: 0] += 1
        }
        lastCategorySummary = summary
        
        // Hent de 5 siste kvitteringene, sortert etter kjøpsdato (nyeste først)
        recentReceipts = Array(receipts.sorted { $0.purchaseDate > $1.purchaseDate }.prefix(5))
    }
}
