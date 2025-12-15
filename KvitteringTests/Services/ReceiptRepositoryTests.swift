import XCTest
import SwiftData
@testable import Kvittering

@MainActor
final class ReceiptRepositoryTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: ReceiptRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([Receipt.self, LineItem.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = modelContainer.mainContext
        repository = ReceiptRepository(context: modelContext)
    }
    
    override func tearDown() async throws {
        repository = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Fetch Tests
    
    func testFetchReceipts_EmptyDatabase_ReturnsEmpty() async {
        let receipts = repository.fetchReceipts()
        XCTAssertTrue(receipts.isEmpty, "Empty database should return empty array")
    }
    
    func testFetchReceipts_WithReceipts_ReturnsAll() async throws {
        // Create test receipts
        let receipt1 = TestHelpers.createMockReceipt(
            storeName: "REMA 1000",
            purchaseDate: TestHelpers.date(year: 2025, month: 1, day: 15),
            totalAmount: 100.00
        )
        let receipt2 = TestHelpers.createMockReceipt(
            storeName: "Elkjøp",
            purchaseDate: TestHelpers.date(year: 2025, month: 1, day: 20),
            totalAmount: 5000.00
        )
        
        try repository.add(receipt: receipt1, image: nil)
        try repository.add(receipt: receipt2, image: nil)
        
        let receipts = repository.fetchReceipts()
        
        XCTAssertEqual(receipts.count, 2, "Should return all receipts")
    }
    
    // MARK: - Category Filter Tests
    
    func testFetchReceipts_ByCategory() async throws {
        let receipt1 = TestHelpers.createMockReceipt(
            storeName: "REMA 1000",
            purchaseDate: Date(),
            totalAmount: 100.00,
            category: .groceries
        )
        let receipt2 = TestHelpers.createMockReceipt(
            storeName: "Elkjøp",
            purchaseDate: Date(),
            totalAmount: 5000.00,
            category: .electronics
        )
        
        try repository.add(receipt: receipt1, image: nil)
        try repository.add(receipt: receipt2, image: nil)
        
        let groceries = repository.fetchReceipts(category: .groceries)
        XCTAssertEqual(groceries.count, 1, "Should filter by category")
        XCTAssertEqual(groceries.first?.storeName, "REMA 1000")
    }
    
    // MARK: - Search Text Tests
    
    func testFetchReceipts_ByStoreName() async throws {
        let receipt1 = TestHelpers.createMockReceipt(storeName: "REMA 1000")
        let receipt2 = TestHelpers.createMockReceipt(storeName: "Elkjøp")
        
        try repository.add(receipt: receipt1, image: nil)
        try repository.add(receipt: receipt2, image: nil)
        
        let results = repository.fetchReceipts(searchText: "rema")
        XCTAssertEqual(results.count, 1, "Should find receipt by store name")
        XCTAssertTrue(results.first?.storeName.lowercased().contains("rema") ?? false)
    }
    
    func testFetchReceipts_SearchIsCaseInsensitive() async throws {
        let receipt = TestHelpers.createMockReceipt(storeName: "REMA 1000")
        try repository.add(receipt: receipt, image: nil)
        
        let results = repository.fetchReceipts(searchText: "rema")
        XCTAssertEqual(results.count, 1, "Search should be case insensitive")
    }
    
    // MARK: - Amount Range Tests
    
    func testFetchReceipts_ByAmountRange() async throws {
        let receipt1 = TestHelpers.createMockReceipt(totalAmount: 100.00)
        let receipt2 = TestHelpers.createMockReceipt(totalAmount: 500.00)
        let receipt3 = TestHelpers.createMockReceipt(totalAmount: 2000.00)
        
        try repository.add(receipt: receipt1, image: nil)
        try repository.add(receipt: receipt2, image: nil)
        try repository.add(receipt: receipt3, image: nil)
        
        let range = Decimal(50)...Decimal(1000)
        let results = repository.fetchReceipts(amountRange: range)
        
        XCTAssertEqual(results.count, 2, "Should filter by amount range")
        XCTAssertTrue(results.allSatisfy { $0.totalAmount >= 50 && $0.totalAmount <= 1000 })
    }
    
    // MARK: - Date Range Tests
    
    func testFetchReceipts_ByDateRange() async throws {
        let receipt1 = TestHelpers.createMockReceipt(
            purchaseDate: TestHelpers.date(year: 2025, month: 1, day: 10)
        )
        let receipt2 = TestHelpers.createMockReceipt(
            purchaseDate: TestHelpers.date(year: 2025, month: 2, day: 15)
        )
        let receipt3 = TestHelpers.createMockReceipt(
            purchaseDate: TestHelpers.date(year: 2025, month: 3, day: 20)
        )
        
        try repository.add(receipt: receipt1, image: nil)
        try repository.add(receipt: receipt2, image: nil)
        try repository.add(receipt: receipt3, image: nil)
        
        let startDate = TestHelpers.date(year: 2025, month: 1, day: 1)
        let endDate = TestHelpers.date(year: 2025, month: 2, day: 28)
        let dateRange = startDate...endDate
        
        let results = repository.fetchReceipts(dateRange: dateRange)
        
        XCTAssertEqual(results.count, 2, "Should filter by date range")
    }
    
    // MARK: - Line Items Search Tests
    
    func testFetchReceipts_ByLineItemsText() async throws {
        let lineItem1 = TestHelpers.createMockLineItem(description: "Melk 1L")
        let lineItem2 = TestHelpers.createMockLineItem(description: "Brød")
        
        let receipt1 = TestHelpers.createMockReceipt(
            storeName: "REMA 1000",
            lineItems: [lineItem1]
        )
        let receipt2 = TestHelpers.createMockReceipt(
            storeName: "Kiwi",
            lineItems: [lineItem2]
        )
        
        try repository.add(receipt: receipt1, image: nil)
        try repository.add(receipt: receipt2, image: nil)
        
        let results = repository.fetchReceipts(
            searchText: "melk",
            searchScope: .lineItems
        )
        
        XCTAssertEqual(results.count, 1, "Should find receipt by line item text")
        XCTAssertTrue(results.first?.lineItems.contains { $0.descriptionText.lowercased().contains("melk") } ?? false)
    }
    
    func testFetchReceipts_SearchAll_IncludesLineItems() async throws {
        let lineItem = TestHelpers.createMockLineItem(description: "Melk 1L")
        let receipt = TestHelpers.createMockReceipt(
            storeName: "REMA 1000",
            lineItems: [lineItem]
        )
        
        try repository.add(receipt: receipt, image: nil)
        
        // Search for text that's in line items but not store name
        let results = repository.fetchReceipts(
            searchText: "melk",
            searchScope: .all
        )
        
        XCTAssertEqual(results.count, 1, "Should find receipt when searching in line items")
    }
    
    // MARK: - Combined Filters Tests
    
    func testFetchReceipts_CombinedFilters() async throws {
        let receipt1 = TestHelpers.createMockReceipt(
            storeName: "REMA 1000",
            purchaseDate: TestHelpers.date(year: 2025, month: 1, day: 15),
            totalAmount: 100.00,
            category: .groceries
        )
        let receipt2 = TestHelpers.createMockReceipt(
            storeName: "Elkjøp",
            purchaseDate: TestHelpers.date(year: 2025, month: 2, day: 20),
            totalAmount: 5000.00,
            category: .electronics
        )
        
        try repository.add(receipt: receipt1, image: nil)
        try repository.add(receipt: receipt2, image: nil)
        
        let filters = SearchFilters(
            category: .groceries,
            searchText: "rema",
            searchScope: .storeName,
            dateRange: TestHelpers.date(year: 2025, month: 1, day: 1)...TestHelpers.date(year: 2025, month: 1, day: 31),
            amountRange: Decimal(50)...Decimal(200)
        )
        
        let results = repository.fetchReceipts(filters: filters)
        
        XCTAssertEqual(results.count, 1, "Should apply all filters correctly")
        XCTAssertEqual(results.first?.storeName, "REMA 1000")
    }
    
    // MARK: - Sorting Tests
    
    func testFetchReceipts_SortedByDate_NewestFirst() async throws {
        let receipt1 = TestHelpers.createMockReceipt(
            purchaseDate: TestHelpers.date(year: 2025, month: 1, day: 10)
        )
        let receipt2 = TestHelpers.createMockReceipt(
            purchaseDate: TestHelpers.date(year: 2025, month: 2, day: 15)
        )
        let receipt3 = TestHelpers.createMockReceipt(
            purchaseDate: TestHelpers.date(year: 2025, month: 1, day: 20)
        )
        
        try repository.add(receipt: receipt1, image: nil)
        try repository.add(receipt: receipt2, image: nil)
        try repository.add(receipt: receipt3, image: nil)
        
        let results = repository.fetchReceipts()
        
        XCTAssertEqual(results.count, 3, "Should return all receipts")
        // Should be sorted newest first
        XCTAssertEqual(results[0].purchaseDate, TestHelpers.date(year: 2025, month: 2, day: 15))
        XCTAssertEqual(results[1].purchaseDate, TestHelpers.date(year: 2025, month: 1, day: 20))
        XCTAssertEqual(results[2].purchaseDate, TestHelpers.date(year: 2025, month: 1, day: 10))
    }
}

