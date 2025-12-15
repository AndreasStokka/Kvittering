import Foundation
import SwiftData

@MainActor
final class ReceiptListViewModel: ObservableObject {
    @Published var receipts: [Receipt] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: Category?
    @Published var searchScope: SearchScope = .storeName
    @Published var dateRange: ClosedRange<Date>?
    @Published var amountRange: ClosedRange<Decimal>?
    @Published var minAmount: Decimal = 0 {
        didSet {
            // Valider at beløpet ikke er NaN eller ugyldig
            if minAmount.isNaN || minAmount.isInfinite {
                minAmount = 0
            }
        }
    }
    @Published var maxAmount: Decimal = 50000 {
        didSet {
            // Valider at beløpet ikke er NaN eller ugyldig
            if maxAmount.isNaN || maxAmount.isInfinite {
                maxAmount = 50000
            }
        }
    }
    @Published var showSearchFilter: Bool = false
    @Published var showCategoryFilter: Bool = false
    @Published var showAmountFilter: Bool = false
    @Published var showDateFilter: Bool = false
    @Published var fromDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @Published var toDate: Date = Date()

    private var repository: ReceiptRepository?

    func attach(context: ModelContext) {
        repository = ReceiptRepository(context: context)
        load()
    }

    func load() {
        guard let repository else { return }
        let filters = SearchFilters(
            category: selectedCategory,
            searchText: searchText,
            searchScope: searchScope,
            dateRange: dateRange,
            amountRange: amountRange
        )
        receipts = repository.fetchReceipts(filters: filters)
    }
    
    func updateAmountRange() {
        // Valider beløp før opprettelse av range
        let min = minAmount.isNaN || minAmount.isInfinite ? 0 : minAmount
        let max = maxAmount.isNaN || maxAmount.isInfinite ? 50000 : maxAmount
        
        if min > 0 || max < 50000 {
            // Sørg for at min <= max
            if min <= max {
                amountRange = min...max
            } else {
                amountRange = nil
            }
        } else {
            amountRange = nil
        }
        load()
    }
    
    func updateDateRange() {
        if fromDate <= toDate {
            dateRange = fromDate...toDate
        } else {
            dateRange = nil
        }
        load()
    }
}
