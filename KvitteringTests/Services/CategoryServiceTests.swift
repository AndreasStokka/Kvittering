import XCTest
@testable import Kvittering

final class CategoryServiceTests: XCTestCase {
    
    var categoryService: CategoryService!
    
    override func setUp() {
        super.setUp()
        categoryService = CategoryService()
    }
    
    override func tearDown() {
        categoryService = nil
        super.tearDown()
    }
    
    // MARK: - Exact Match Tests
    
    func testSuggestedCategory_ExactMatch_Rema() {
        let category = categoryService.suggestedCategory(for: "rema")
        XCTAssertEqual(category, .groceries, "Rema should map to groceries")
    }
    
    func testSuggestedCategory_ExactMatch_Elkjop() {
        let category = categoryService.suggestedCategory(for: "elkjøp")
        XCTAssertEqual(category, .electronics, "Elkjøp should map to electronics")
    }
    
    func testSuggestedCategory_ExactMatch_XXL() {
        let category = categoryService.suggestedCategory(for: "xxl")
        XCTAssertEqual(category, .sports, "XXL should map to sports")
    }
    
    // MARK: - Contains Match Tests
    
    func testSuggestedCategory_ContainsMatch_Sport1() {
        let category = categoryService.suggestedCategory(for: "sport 1 førde")
        XCTAssertEqual(category, .sports, "Sport 1 should map to sports")
    }
    
    func testSuggestedCategory_ContainsMatch_CaseInsensitive() {
        let category = categoryService.suggestedCategory(for: "REMA 1000")
        XCTAssertEqual(category, .groceries, "Should be case insensitive")
    }
    
    func testSuggestedCategory_ContainsMatch_WithDiacritics() {
        let category = categoryService.suggestedCategory(for: "Elkjöp") // Med diakritisk tegn
        XCTAssertEqual(category, .electronics, "Should handle diacritics")
    }
    
    // MARK: - Keyword-Based Fallback Tests
    
    func testSuggestedCategory_Keyword_Apotek() {
        let category = categoryService.suggestedCategory(for: "Apotek 1")
        XCTAssertEqual(category, .other, "Apotek should map to other via keyword")
    }
    
    func testSuggestedCategory_Keyword_Bensin() {
        let category = categoryService.suggestedCategory(for: "Circle K Bensinstasjon")
        XCTAssertEqual(category, .other, "Bensin should map to other (transport category removed)")
    }
    
    func testSuggestedCategory_Keyword_Bygg() {
        let category = categoryService.suggestedCategory(for: "Byggmax butikk")
        XCTAssertEqual(category, .construction, "Bygg should map to construction")
    }
    
    func testSuggestedCategory_ExactMatch_Byggmax() {
        let category = categoryService.suggestedCategory(for: "byggmax")
        XCTAssertEqual(category, .construction, "Byggmax should map to construction")
    }
    
    func testSuggestedCategory_Keyword_Supermarked() {
        let category = categoryService.suggestedCategory(for: "Lokalt Supermarked")
        XCTAssertEqual(category, .groceries, "Supermarked should map to groceries")
    }
    
    func testSuggestedCategory_Keyword_Elektronikk() {
        let category = categoryService.suggestedCategory(for: "Elektronikkbutikk AS")
        XCTAssertEqual(category, .electronics, "Elektronikk should map to electronics")
    }
    
    func testSuggestedCategory_Keyword_Sport() {
        let category = categoryService.suggestedCategory(for: "Idrettsbutikk")
        XCTAssertEqual(category, .sports, "Idrett should map to sports")
    }
    
    func testSuggestedCategory_Keyword_Clothes() {
        let category = categoryService.suggestedCategory(for: "Dressmann butikk")
        XCTAssertEqual(category, .clothes, "Dress should map to clothes")
    }
    
    // MARK: - Unknown Store Tests
    
    func testSuggestedCategory_UnknownStore_ReturnsOther() {
        let category = categoryService.suggestedCategory(for: "Ukjent Butikk XYZ")
        XCTAssertEqual(category, .other, "Unknown store should return other")
    }
    
    func testSuggestedCategory_EmptyString_ReturnsOther() {
        let category = categoryService.suggestedCategory(for: "")
        XCTAssertEqual(category, .other, "Empty string should return other")
    }
    
    // MARK: - Edge Cases
    
    func testSuggestedCategory_OnlyNumbers_ReturnsOther() {
        let category = categoryService.suggestedCategory(for: "12345")
        XCTAssertEqual(category, .other, "Numbers only should return other")
    }
    
    func testSuggestedCategory_VeryLongName() {
        let longName = String(repeating: "a", count: 200)
        let category = categoryService.suggestedCategory(for: longName)
        // Should not crash and return some category
        XCTAssertNotNil(category)
    }
    
    // MARK: - Real-World Store Names
    
    func testSuggestedCategory_RealWorld_Rema1000() {
        let category = categoryService.suggestedCategory(for: "REMA 1000 Majorstuen")
        XCTAssertEqual(category, .groceries, "REMA 1000 should map to groceries")
    }
    
    func testSuggestedCategory_RealWorld_Power() {
        let category = categoryService.suggestedCategory(for: "Power Elektro")
        XCTAssertEqual(category, .electronics, "Power should map to electronics")
    }
    
    func testSuggestedCategory_RealWorld_Vinmonopolet() {
        let category = categoryService.suggestedCategory(for: "Vinmonopolet")
        // Vinmonopolet is in JSON, should map to .other
        XCTAssertNotNil(category)
    }
}



