import Foundation
import SwiftData

@MainActor
final class ReceiptListViewModel: ObservableObject {
    @Published var receipts: [Receipt] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: Category?
    @Published var dateRange: ClosedRange<Date>?

    private var repository: ReceiptRepository?

    func attach(context: ModelContext) {
        repository = ReceiptRepository(context: context)
        load()
    }

    func load() {
        guard let repository else { return }
        receipts = repository.fetchReceipts(category: selectedCategory, searchText: searchText, dateRange: dateRange)
    }
}
