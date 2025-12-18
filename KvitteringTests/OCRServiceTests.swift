import XCTest
@testable import Kvittering

final class OCRServiceTests: XCTestCase {
    
    func testParsesDateAndAmount() {
        let text = """
        REMA 1000
        Dato: 12.04.2024
        Total 123,45
        """
        let service = OCRService()
        let result = service.parse(from: text)
        
        XCTAssertNotNil(result.purchaseDate, "Purchase date should be parsed")
        XCTAssertEqual(result.totalAmount, Decimal(string: "123.45"), "Total amount should match")
        XCTAssertEqual(result.storeName, "Rema 1000", "Store name should match")
    }
}
