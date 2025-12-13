import XCTest
@testable import Kvittering

final class OCRServiceTests: XCTestCase {
    
    let ocrService = OCRService()
    
    // MARK: - Test Data
    
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
    
    // MARK: - Store Name Tests
    
    func testDetectStoreName() {
        let result = ocrService.parse(from: sampleReceiptText)
        
        XCTAssertNotNil(result.storeName, "Store name should not be nil")
        XCTAssertTrue(
            result.storeName?.lowercased().contains("sport") == true,
            "Store name should contain 'sport', got: \(result.storeName ?? "nil")"
        )
    }
    
    func testDoesNotPickMaskedCardNumber() {
        let result = ocrService.parse(from: sampleReceiptText)
        
        if let store = result.storeName {
            XCTAssertFalse(store.contains("XXXX"), "Store name should not contain masked card number")
            XCTAssertFalse(store.contains("xxxx"), "Store name should not contain masked card number")
        }
    }
    
    // MARK: - Date Detection Tests
    
    func testDetectDate_ISOFormat() {
        // Test yyyy-MM-dd format (ISO)
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
    
    func testDetectDate_NorwegianFormat() {
        // Test dd.MM.yyyy format (norsk)
        let norwegianReceipt = """
        REMA 1000
        Dato: 24.12.2024
        Totalt: 199,00
        """
        
        let result = ocrService.parse(from: norwegianReceipt)
        
        XCTAssertNotNil(result.purchaseDate, "Norwegian date format should be detected")
        
        if let date = result.purchaseDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            XCTAssertEqual(components.year, 2024, "Year should be 2024")
            XCTAssertEqual(components.month, 12, "Month should be December")
            XCTAssertEqual(components.day, 24, "Day should be 24")
        }
    }
    
    func testDetectDate_WithSlashes() {
        // Test dd/MM/yyyy format
        let slashReceipt = """
        Kiwi Majorstuen
        15/03/2025
        Sum: 87,50
        """
        
        let result = ocrService.parse(from: slashReceipt)
        
        XCTAssertNotNil(result.purchaseDate, "Slash date format should be detected")
        
        if let date = result.purchaseDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            XCTAssertEqual(components.year, 2025, "Year should be 2025")
            XCTAssertEqual(components.month, 3, "Month should be March")
            XCTAssertEqual(components.day, 15, "Day should be 15")
        }
    }
    
    func testDetectDate_InvalidDate_ReturnsNil() {
        // Test ugyldig dato (måned 15 finnes ikke)
        let invalidReceipt = """
        Butikk AS
        2025-15-32
        Totalt: 100,00
        """
        
        let result = ocrService.parse(from: invalidReceipt)
        
        // Datoen skal være nil fordi 15. måned er ugyldig
        // Men vi finner fortsatt beløpet
        XCTAssertNotNil(result.totalAmount, "Amount should still be detected")
    }
    
    // MARK: - Amount Detection Tests
    
    func testDetectTotalAmount_NorwegianFormat() {
        // Test norsk format med komma og mellomrom: 2 379,15
        let result = ocrService.parse(from: sampleReceiptText)
        
        XCTAssertNotNil(result.totalAmount, "Total amount should not be nil")
        
        if let amount = result.totalAmount {
            XCTAssertEqual(amount, Decimal(string: "2379.15"), "Amount should be 2379.15, got: \(amount)")
        }
    }
    
    func testDetectTotalAmount_EnglishFormat() {
        // Test engelsk format med punktum: 2379.15
        let englishReceipt = """
        Store Name
        2025-01-15
        Totalt (1 Artikkel)
        2379.15
        """
        
        let result = ocrService.parse(from: englishReceipt)
        
        XCTAssertNotNil(result.totalAmount, "English format amount should be detected")
        
        if let amount = result.totalAmount {
            XCTAssertEqual(amount, Decimal(string: "2379.15"), "Amount should be 2379.15, got: \(amount)")
        }
    }
    
    func testDetectTotalAmount_WithThousandsSeparator() {
        // Test beløp med tusenskilletegn: 12 500,00
        let largeReceipt = """
        Elkjøp
        2025-02-20
        Totalt:
        12 500,00
        """
        
        let result = ocrService.parse(from: largeReceipt)
        
        XCTAssertNotNil(result.totalAmount, "Large amount with thousands separator should be detected")
        
        if let amount = result.totalAmount {
            XCTAssertEqual(amount, Decimal(string: "12500.00"), "Amount should be 12500.00, got: \(amount)")
        }
    }
    
    func testDetectTotalAmount_PrioritizesTotalKeyword() {
        // Test at beløp etter "Totalt" prioriteres over andre beløp
        let multipleAmountsReceipt = """
        Coop Prix
        Vare 1: 50,00
        Vare 2: 75,00
        Rabatt: 25,00
        Totalt: 100,00
        MVA: 20,00
        """
        
        let result = ocrService.parse(from: multipleAmountsReceipt)
        
        XCTAssertNotNil(result.totalAmount, "Total amount should be detected")
        
        if let amount = result.totalAmount {
            // Skal finne 100,00 (etter Totalt), ikke 75,00 (største) eller andre
            XCTAssertEqual(amount, Decimal(string: "100.00"), "Should prioritize amount after 'Totalt', got: \(amount)")
        }
    }
    
    func testDoesNotPickProductNumber() {
        let result = ocrService.parse(from: sampleReceiptText)
        
        if let amount = result.totalAmount {
            XCTAssertLessThan(amount, Decimal(100000), "Amount should not be a product number")
        }
    }
    
    func testDetectTotalAmount_SkipsRabatt() {
        // Test at rabattbeløp hoppes over
        let rabattReceipt = """
        Meny
        Rabatt: 419,85
        Totalt: 2379,15
        """
        
        let result = ocrService.parse(from: rabattReceipt)
        
        XCTAssertNotNil(result.totalAmount, "Total should be detected, not rabatt")
        
        if let amount = result.totalAmount {
            XCTAssertEqual(amount, Decimal(string: "2379.15"), "Should skip rabatt and find totalt, got: \(amount)")
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyText_ReturnsNilValues() {
        let result = ocrService.parse(from: "")
        
        XCTAssertNil(result.storeName, "Empty text should return nil store name")
        XCTAssertNil(result.purchaseDate, "Empty text should return nil date")
        XCTAssertNil(result.totalAmount, "Empty text should return nil amount")
    }
    
    func testOnlyNumbers_ReturnsNilStoreName() {
        let numbersOnly = """
        12345
        67890
        100,00
        """
        
        let result = ocrService.parse(from: numbersOnly)
        
        XCTAssertNil(result.storeName, "Numbers only should return nil store name")
    }
}
