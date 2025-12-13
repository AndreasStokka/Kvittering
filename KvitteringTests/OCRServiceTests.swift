import XCTest
@testable import Kvittering

final class OCRServiceTests: XCTestCase {
    
    let ocrService = OCRService()
    
    // Simulert OCR-tekst fra Sport 1 kvittering
    let sampleReceiptText = """
    sport 1
    SPORT 1 FØRDE AS
    6800 FØRDE
    TELEFON 57 72 00 67
    Butikk 11094-1, Selger 84
    Salgskvittering 494638 2025-10-16 17:28
    Essentials 3L Shell
    7031582534143 FIRE RED M
    Rabatt: NOK 419.85 (15% av 2 799.00)
    Totalt (1 Artikkel)
    Bank:
    2 379,15
    2 379,15
    Rabatter
    419,85
    Sport 1 Førde
    Naustdalsveien 1A
    FØRDE
    Org. Nr: 995263947 2025-10-16
    17
    :28
    VAREKJØP NOK 2379.15 BankAxept PSN
    :00
    KONTAKTLØS XXXX XXXX XXXX XXX2
    248
    TERM: 03478215-042614 NETSNO 605620 KC1
    ATC:00093
    010 AED: AID: D5780000021
    ARC:00
    5377
    STATUS:000 Autorisasjonskode 00
    REF:042614
    Resultat: Autoris
    ert
    Behold kvittering
    KORTHOLDERS KOPI
    MVA-grunnlag MVA-% MVA Sum
    1903.32 25% 475.83 2379.15
    Medlemsnr. 18010000966674
    Bytterett innan 14 dagar,
    Kun mot kvittering/byttelapp
    """
    
    func testDetectStoreName() {
        let result = ocrService.parse(from: sampleReceiptText)
        
        // Skal finne "sport 1" eller lignende
        XCTAssertNotNil(result.storeName, "Store name should not be nil")
        XCTAssertTrue(
            result.storeName?.lowercased().contains("sport") == true,
            "Store name should contain 'sport', got: \(result.storeName ?? "nil")"
        )
    }
    
    func testDetectDate() {
        let result = ocrService.parse(from: sampleReceiptText)
        
        XCTAssertNotNil(result.purchaseDate, "Date should not be nil")
        
        if let date = result.purchaseDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            XCTAssertEqual(components.year, 2025, "Year should be 2025")
            XCTAssertEqual(components.month, 10, "Month should be October")
            XCTAssertEqual(components.day, 16, "Day should be 16")
        }
    }
    
    func testDetectTotalAmount() {
        let result = ocrService.parse(from: sampleReceiptText)
        
        XCTAssertNotNil(result.totalAmount, "Total amount should not be nil")
        
        if let amount = result.totalAmount {
            // Beløpet skal være 2379.15
            XCTAssertEqual(amount, Decimal(string: "2379.15"), "Amount should be 2379.15, got: \(amount)")
        }
    }
    
    func testDoesNotPickMaskedCardNumber() {
        let result = ocrService.parse(from: sampleReceiptText)
        
        // Butikknavn skal IKKE være maskert kortnummer
        if let store = result.storeName {
            XCTAssertFalse(store.contains("XXXX"), "Store name should not contain masked card number")
            XCTAssertFalse(store.contains("xxxx"), "Store name should not contain masked card number")
        }
    }
    
    func testDoesNotPickProductNumber() {
        let result = ocrService.parse(from: sampleReceiptText)
        
        if let amount = result.totalAmount {
            // Beløpet skal IKKE være produktnummer
            XCTAssertLessThan(amount, Decimal(100000), "Amount should not be a product number")
        }
    }
}
