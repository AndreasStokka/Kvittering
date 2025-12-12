import Testing
@testable import Kvittering

struct OCRServiceTests {
    @Test
    func parsesDateAndAmount() async throws {
        let text = """
        REMA 1000
        Dato: 12.04.2024
        Total 123,45
        """
        let service = OCRService()
        let result = service.parse(from: text)
        #expect(result.purchaseDate != nil)
        #expect(result.totalAmount == Decimal(string: "123.45"))
        #expect(result.storeName == "Rema 1000")
    }
}
