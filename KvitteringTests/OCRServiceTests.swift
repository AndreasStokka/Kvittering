import XCTest
@testable import Kvittering

final class OCRServiceTests: XCTestCase {
    
    // MARK: - Norwegian Characters Tests
    
    func testParsesNorwegianCharacters() {
        // Test med æ/ø/å i produktnavn
        let text = """
        KIWI
        Dato: 15.04.2024
        Ærter 500g 29,90
        Øl 6-pack 89,50
        Åpne melk 1L 18,90
        Total 138,30
        """
        let service = OCRService()
        let result = service.parse(from: text)
        
        XCTAssertEqual(result.lineItems.count, 3, "Should parse 3 line items")
        
        let item1 = result.lineItems[0]
        XCTAssertTrue(item1.descriptionText.contains("Ærter") || item1.descriptionText.contains("Erter"), "Should contain Ærter")
        XCTAssertEqual(item1.unitPrice, Decimal(string: "29.90"))
        
        let item2 = result.lineItems[1]
        XCTAssertTrue(item2.descriptionText.contains("Øl") || item2.descriptionText.contains("Ol"), "Should contain Øl")
        XCTAssertEqual(item2.unitPrice, Decimal(string: "89.50"))
        
        let item3 = result.lineItems[2]
        XCTAssertTrue(item3.descriptionText.contains("Åpne") || item3.descriptionText.contains("Apne"), "Should contain Åpne")
        XCTAssertEqual(item3.unitPrice, Decimal(string: "18.90"))
    }
    
    func testCorrectsNorwegianCharactersFromOCR() {
        // Test korrigering av OCR-feil: oe→ø, ae→æ, aa→å
        let text = """
        SPAR
        Dato: 20.04.2024
        Melk 1L oe 18,90
        Kaese ae 45,00
        Sild aa 32,50
        Total 96,40
        """
        let service = OCRService()
        let result = service.parse(from: text)
        
        // Verifiser at produktnavnene er korrigert
        XCTAssertGreaterThan(result.lineItems.count, 0, "Should parse at least one item")
        
        // Sjekk at korrigering er gjort (normalisert tekst skal inneholde norske bokstaver eller være korrekt matchet)
        let allDescriptions = result.lineItems.map { $0.descriptionText.lowercased() }.joined(separator: " ")
        // Vi forventer at normalisering har skjedd (kan være gjennom correctNorwegianCharacters eller matching)
        // Sjekk at de feilaktige OCR-variantene ikke er tilstede, eller at korrigerte varianter er tilstede
        XCTAssertFalse(allDescriptions.contains(" oe ") || allDescriptions.hasPrefix("oe ") || allDescriptions.hasSuffix(" oe"), "Should not contain uncorrected 'oe'")
        XCTAssertFalse(allDescriptions.contains(" ae ") || allDescriptions.hasPrefix("ae ") || allDescriptions.hasSuffix(" ae"), "Should not contain uncorrected 'ae'")
        XCTAssertFalse(allDescriptions.contains(" aa ") || allDescriptions.hasPrefix("aa ") || allDescriptions.hasSuffix(" aa"), "Should not contain uncorrected 'aa'")
        XCTAssertNotNil(result.storeName, "Store name should be parsed")
    }
    
    // MARK: - Multi-line Items Tests
    
    func testParsesMultiLineItems() {
        // Test flerlinjevarer hvor produktnavn er på en linje og pris på neste
        let text = """
        MENY
        Dato: 18.04.2024
        Essentials 3L Shell
        2 379.15
        Coop Melk 1L
        18,90
        Total 2 398,05
        """
        let service = OCRService()
        let result = service.parse(from: text)
        
        XCTAssertGreaterThan(result.lineItems.count, 0, "Should parse at least 1 line item")
        XCTAssertGreaterThanOrEqual(result.lineItems.count, 2, "Should parse at least 2 multi-line items")
        
        // Første vare: Essentials 3L Shell
        let item1 = result.lineItems[0]
        XCTAssertTrue(item1.descriptionText.contains("Essentials"), "First item should contain 'Essentials'")
        XCTAssertEqual(item1.unitPrice, Decimal(string: "2379.15"), "First item price should be 2379.15")
        
        // Andre vare: Coop Melk 1L
        let item2 = result.lineItems[1]
        XCTAssertTrue(item2.descriptionText.contains("Melk"), "Second item should contain 'Melk'")
        XCTAssertEqual(item2.unitPrice, Decimal(string: "18.90"), "Second item price should be 18.90")
    }
    
    // MARK: - Discount Tests
    
    func testParsesDiscountLines() {
        // Test rabattlinjer med negative beløp
        let text = """
        REMA 1000
        Dato: 25.04.2024
        Melk 1L 18,90
        Rabatt -5,00
        Total 13,90
        """
        let service = OCRService()
        let result = service.parse(from: text)
        
        XCTAssertGreaterThanOrEqual(result.lineItems.count, 1, "Should parse at least one item")
        
        // Finn rabattlinjen
        let discountItems = result.lineItems.filter { $0.lineTotal < 0 || $0.descriptionText.lowercased().contains("rabatt") }
        XCTAssertGreaterThan(discountItems.count, 0, "Should parse discount line")
        
        if let discountItem = discountItems.first {
            XCTAssertTrue(discountItem.lineTotal < 0, "Discount should have negative lineTotal")
            XCTAssertEqual(discountItem.unitPrice, Decimal(string: "5.00"), "Discount unitPrice should be absolute value")
        }
    }
    
    func testParsesNegativeDiscountAmount() {
        // Test eksplisitt negativt beløp i rabatt
        let text = """
        KIWI
        Dato: 26.04.2024
        Brød 29,50
        -10,00
        Total 19,50
        """
        let service = OCRService()
        let result = service.parse(from: text)
        
        // Sjekk at negativt beløp er parset
        let negativeItems = result.lineItems.filter { $0.lineTotal < 0 }
        XCTAssertGreaterThan(negativeItems.count, 0, "Should parse negative discount amount")
    }
    
    func testParsesDiscountWithKrSuffix() {
        // Test rabatt med kr/NOK suffix
        let text = """
        COOP EXTRA
        Dato: 27.04.2024
        Vare 1 100,00
        Rabatt -15,50 kr
        Total 84,50
        """
        let service = OCRService()
        let result = service.parse(from: text)
        
        let discountItems = result.lineItems.filter { $0.lineTotal < 0 || $0.descriptionText.lowercased().contains("rabatt") }
        XCTAssertGreaterThan(discountItems.count, 0, "Should parse discount with kr suffix")
        
        if let discountItem = discountItems.first {
            XCTAssertTrue(discountItem.lineTotal < 0, "Discount should have negative lineTotal")
            XCTAssertEqual(discountItem.unitPrice, Decimal(string: "15.50"), "Should parse amount with kr suffix")
        }
    }
    
    // MARK: - Combined Tests
    
    func testParsesComplexReceiptWithNorwegianCharactersAndMultiLineItems() {
        // Kombinert test med norske bokstaver, flerlinjevarer og rabatter
        let text = """
        MENY
        Dato: 28.04.2024
        Ærter 500g 29,90
        Øl 6-pack
        89,50
        Åpne melk 1L
        18,90
        Rabatt -10,00
        Total 128,30
        """
        let service = OCRService()
        let result = service.parse(from: text)
        
        XCTAssertGreaterThanOrEqual(result.lineItems.count, 3, "Should parse at least 3 items")
        
        // Sjekk at alle elementer er parset
        let allDescriptions = result.lineItems.map { $0.descriptionText.lowercased() }.joined(separator: " ")
        XCTAssertTrue(allDescriptions.contains("erter") || allDescriptions.contains("ærter"), "Should contain Ærter")
        XCTAssertTrue(allDescriptions.contains("ol") || allDescriptions.contains("øl"), "Should contain Øl")
        XCTAssertTrue(allDescriptions.contains("apne") || allDescriptions.contains("åpne"), "Should contain Åpne")
        
        // Sjekk at rabatt er inkludert
        let hasDiscount = result.lineItems.contains { $0.lineTotal < 0 || $0.descriptionText.lowercased().contains("rabatt") }
        XCTAssertTrue(hasDiscount, "Should include discount line")
    }
}
