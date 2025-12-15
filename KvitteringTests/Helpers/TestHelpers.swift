import Foundation
@testable import Kvittering

/// Helper functions and mock data for testing
struct TestHelpers {
    
    // MARK: - Sample Receipt Text
    
    static let sampleReceiptTextWithLineItems = """
    sport 1
    SPORT 1 FØRDE AS
    2025-10-16
    Essentials 3L Shell 2 379,15
    Rabatt: 419,85
    Totalt: 2 379,15
    """
    
    static let sampleReceiptTextWithMultipleItems = """
    REMA 1000
    2025-01-15
    Melk 1L 25,90
    Brød 2x 19,50
    Smør 45,00
    Totalt: 90,40
    """
    
    static let sampleReceiptTextWithQuantity = """
    Kiwi
    2025-02-20
    3x Epler 45,00
    2x Bananer 30,00
    Totalt: 75,00
    """
    
    // MARK: - Mock Receipts
    
    static func createMockReceipt(
        id: UUID = UUID(),
        ownerId: String = "test-user",
        storeName: String = "Test Store",
        purchaseDate: Date = Date(),
        totalAmount: Decimal = 100.00,
        category: Kvittering.Category = .other,
        lineItems: [LineItem] = []
    ) -> Receipt {
        return Receipt(
            id: id,
            ownerId: ownerId,
            storeName: storeName,
            purchaseDate: purchaseDate,
            totalAmount: totalAmount,
            category: category.rawValue,
            lineItems: lineItems,
            imagePath: nil,
            note: nil
        )
    }
    
    static func createMockLineItem(
        description: String = "Test Product",
        quantity: Decimal = 1,
        unitPrice: Decimal = 50.00
    ) -> LineItem {
        return LineItem(
            descriptionText: description,
            quantity: quantity,
            unitPrice: unitPrice,
            lineTotal: quantity * unitPrice
        )
    }
    
    // MARK: - Date Helpers
    
    static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}

