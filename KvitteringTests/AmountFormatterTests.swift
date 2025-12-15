//
//  AmountFormatterTests.swift
//  Kvittering
//
//  Created by Andreas jr. Stokka on 14/12/2025.
//

import XCTest
@testable import Kvittering

final class AmountFormatterTests: XCTestCase {
    
    // MARK: - Test norsk formatering med tusenskille og komma
    
    func testFormatAmount_WithThousandsSeparator() {
        // Test at beløp med tusenvis formateres med space som tusenskille
        let amount = Decimal(string: "1566.32")!
        let result = AmountFormatter.format(amount)
        
        XCTAssertEqual(result, "kr 1 566,32", "Beløp skal formateres med space som tusenskille og komma som desimaltall")
    }
    
    func testFormatAmount_SmallAmount() {
        // Test små beløp uten tusenvis
        let amount = Decimal(string: "99.50")!
        let result = AmountFormatter.format(amount)
        
        XCTAssertEqual(result, "kr 99,50", "Små beløp skal formateres med komma som desimaltall")
    }
    
    func testFormatAmount_LargeAmount() {
        // Test store beløp med flere tusenvis
        let amount = Decimal(string: "123456.78")!
        let result = AmountFormatter.format(amount)
        
        XCTAssertEqual(result, "kr 123 456,78", "Store beløp skal formateres med space som tusenskille")
    }
    
    func testFormatAmount_Zero() {
        // Test at null formateres riktig
        let amount = Decimal(0)
        let result = AmountFormatter.format(amount)
        
        XCTAssertEqual(result, "kr 0,00", "Null skal formateres som kr 0,00")
    }
    
    func testFormatAmount_NaN() {
        // Test at NaN håndteres riktig
        let amount = Decimal.nan
        let result = AmountFormatter.format(amount)
        
        XCTAssertEqual(result, "kr 0,00", "NaN skal formateres som kr 0,00")
    }
    
    func testFormatAmount_Infinite() {
        // Test at uendelig håndteres riktig
        let amount = Decimal(1) / Decimal(0) // Simulerer infinity
        let result = AmountFormatter.format(amount)
        
        XCTAssertEqual(result, "kr 0,00", "Uendelig skal formateres som kr 0,00")
    }
    
    func testFormatAmount_ExactExample() {
        // Test med eksakt eksempel fra brukerens spørsmål
        let amount = Decimal(string: "1566.32")!
        let result = AmountFormatter.format(amount)
        
        XCTAssertEqual(result, "kr 1 566,32", "Skal matche eksakt format: kr 1 566,32")
    }
}
