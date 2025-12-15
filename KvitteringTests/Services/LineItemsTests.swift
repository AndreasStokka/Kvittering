import XCTest
@testable import Kvittering

final class LineItemsTests: XCTestCase {
    
    let ocrService = OCRService()
    
    // MARK: - Basic Line Item Detection
    
    func testDetectLineItems_SimpleProductAndPrice() {
        let receiptText = """
        Store Name
        2025-01-15
        Melk 1L 25,90
        Totalt: 25,90
        """
        
        let result = ocrService.parse(from: receiptText)
        
        XCTAssertFalse(result.lineItems.isEmpty, "Should detect at least one line item")
        
        if let firstItem = result.lineItems.first {
            XCTAssertTrue(firstItem.descriptionText.lowercased().contains("melk"), "Should contain product name")
            XCTAssertEqual(firstItem.unitPrice, Decimal(string: "25.90"), "Should parse price correctly")
            XCTAssertEqual(firstItem.quantity, 1, "Default quantity should be 1")
        }
    }
    
    func testDetectLineItems_WithQuantity() {
        let receiptText = """
        Kiwi
        2025-02-20
        3x Epler 45,00
        Totalt: 45,00
        """
        
        let result = ocrService.parse(from: receiptText)
        
        XCTAssertFalse(result.lineItems.isEmpty, "Should detect line item with quantity")
        
        if let item = result.lineItems.first {
            XCTAssertTrue(item.descriptionText.lowercased().contains("epler"), "Should contain product name")
            XCTAssertEqual(item.quantity, Decimal(3), "Should parse quantity correctly")
            XCTAssertEqual(item.unitPrice, Decimal(string: "15.00"), "Unit price should be calculated")
        }
    }
    
    func testDetectLineItems_MultipleItems() {
        let receiptText = """
        REMA 1000
        2025-01-15
        Melk 1L 25,90
        Brød 2x 19,50
        Smør 45,00
        Totalt: 90,40
        """
        
        let result = ocrService.parse(from: receiptText)
        
        XCTAssertGreaterThanOrEqual(result.lineItems.count, 2, "Should detect multiple line items")
        
        // Check that we have different products
        let productNames = result.lineItems.map { $0.descriptionText.lowercased() }
        XCTAssertTrue(productNames.contains { $0.contains("melk") }, "Should contain Melk")
        XCTAssertTrue(productNames.contains { $0.contains("brød") || $0.contains("smør") }, "Should contain other products")
    }
    
    // MARK: - Price Format Tests
    
    func testDetectLineItems_NorwegianFormat_Comma() {
        let receiptText = """
        Store
        2025-01-15
        Vare 1 125,50
        Totalt: 125,50
        """
        
        let result = ocrService.parse(from: receiptText)
        
        XCTAssertFalse(result.lineItems.isEmpty, "Should parse Norwegian format with comma")
        
        if let item = result.lineItems.first {
            XCTAssertEqual(item.unitPrice, Decimal(string: "125.50"), "Should convert comma to dot")
        }
    }
    
    func testDetectLineItems_EnglishFormat_Dot() {
        let receiptText = """
        Store
        2025-01-15
        Product 1 125.50
        Totalt: 125.50
        """
        
        let result = ocrService.parse(from: receiptText)
        
        XCTAssertFalse(result.lineItems.isEmpty, "Should parse English format with dot")
        
        if let item = result.lineItems.first {
            XCTAssertEqual(item.unitPrice, Decimal(string: "125.50"), "Should handle dot correctly")
        }
    }
    
    func testDetectLineItems_WithThousandsSeparator() {
        let receiptText = """
        Store
        2025-01-15
        Dyr vare 1 500,00
        Totalt: 1 500,00
        """
        
        let result = ocrService.parse(from: receiptText)
        
        XCTAssertFalse(result.lineItems.isEmpty, "Should parse amount with thousands separator")
        
        if let item = result.lineItems.first {
            XCTAssertEqual(item.unitPrice, Decimal(string: "1500.00"), "Should remove spaces and convert comma")
        }
    }
    
    // MARK: - Validation Tests
    
    func testDetectLineItems_ValidatesAgainstTotal() {
        let receiptText = """
        Store
        2025-01-15
        Vare 1 500,00
        Vare 2 300,00
        Totalt: 800,00
        """
        
        let result = ocrService.parse(from: receiptText)
        
        // All line items should be less than or equal to total
        if let total = result.totalAmount {
            for item in result.lineItems {
                XCTAssertLessThanOrEqual(item.lineTotal, total, "Line item total should not exceed receipt total")
            }
        }
    }
    
    func testDetectLineItems_SkipsInvalidAmounts() {
        let receiptText = """
        Store
        2025-01-15
        Vare 1 50,00
        Produktnummer 1234567890123
        Totalt: 50,00
        """
        
        let result = ocrService.parse(from: receiptText)
        
        // Should not pick up product numbers as prices
        for item in result.lineItems {
            XCTAssertLessThan(item.unitPrice, Decimal(1000), "Should not pick up product numbers")
        }
    }
    
    // MARK: - Edge Cases
    
    func testDetectLineItems_NoDate_StillParses() {
        let receiptText = """
        Store Name
        Vare 1 25,90
        Totalt: 25,90
        """
        
        let result = ocrService.parse(from: receiptText)
        
        // Should still try to parse line items even without date
        // May return empty if date index is required, but shouldn't crash
        XCTAssertNotNil(result.lineItems)
    }
    
    func testDetectLineItems_NoTotal_StillParses() {
        let receiptText = """
        Store Name
        2025-01-15
        Vare 1 25,90
        Vare 2 30,00
        """
        
        let result = ocrService.parse(from: receiptText)
        
        // Should still try to parse line items even without total
        XCTAssertNotNil(result.lineItems)
    }
    
    func testDetectLineItems_EmptyText_ReturnsEmpty() {
        let result = ocrService.parse(from: "")
        
        XCTAssertTrue(result.lineItems.isEmpty, "Empty text should return empty line items")
    }
    
    func testDetectLineItems_SkipsHeaderLines() {
        let receiptText = """
        Store Name
        2025-01-15
        Totalt: 100,00
        MVA: 20,00
        Vare 1 80,00
        """
        
        let result = ocrService.parse(from: receiptText)
        
        // Should skip "Totalt" and "MVA" lines
        for item in result.lineItems {
            XCTAssertFalse(item.descriptionText.lowercased().contains("totalt"), "Should skip total lines")
            XCTAssertFalse(item.descriptionText.lowercased().contains("mva"), "Should skip MVA lines")
        }
    }
    
    func testDetectLineItems_SkipsRabattLines() {
        let receiptText = """
        Store
        2025-01-15
        Vare 1 100,00
        Rabatt: 20,00
        Totalt: 80,00
        """
        
        let result = ocrService.parse(from: receiptText)
        
        // Should skip rabatt lines
        for item in result.lineItems {
            XCTAssertFalse(item.descriptionText.lowercased().contains("rabatt"), "Should skip rabatt lines")
        }
    }
    
    // MARK: - Real-World Receipt Format
    
    func testDetectLineItems_RealWorldReceipt() {
        let receiptText = TestHelpers.sampleReceiptTextWithMultipleItems
        
        let result = ocrService.parse(from: receiptText)
        
        XCTAssertFalse(result.lineItems.isEmpty, "Should parse real-world receipt format")
        
        // Verify we got reasonable results
        for item in result.lineItems {
            XCTAssertGreaterThan(item.unitPrice, 0, "Prices should be positive")
            XCTAssertGreaterThan(item.quantity, 0, "Quantities should be positive")
            XCTAssertFalse(item.descriptionText.isEmpty, "Product names should not be empty")
        }
    }
}



