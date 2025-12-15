//
//  AmountsFormatter.swift
//  Kvittering
//
//  Created by Andreas jr. Stokka on 14/12/2025.
//

import Foundation

/// Utility for å formatere beløp med norsk format
public struct AmountFormatter {
    /// Norsk tallformatter for beløp med tusenskilletegn
    private static let norwegianNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "nb_NO")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        return formatter
    }()
    
    /// Formaterer et beløp med norsk format: "kr 1 566,32"
    public static func format(_ amount: Decimal) -> String {
        // Sjekk for NaN og ugyldige verdier
        if amount.isNaN || amount.isInfinite {
            return "kr 0,00"
        }
        
        // Konverter til NSDecimalNumber på en sikker måte
        let nsDecimal = NSDecimalNumber(decimal: amount)
        let doubleValue = nsDecimal.doubleValue
        // Valider doubleValue før formatering
        if doubleValue.isNaN || doubleValue.isInfinite {
            return "kr 0,00"
        }
        
        guard let formatted = norwegianNumberFormatter.string(from: nsDecimal) else {
            return "kr 0,00"
        }
        
        return "kr \(formatted)"
    }
}

/// Utility for å formatere datoer med norsk format
struct ReceiptDateFormatter {
    /// Datoformatter for dd.mm.yyyy format
    private static let dateFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter
    }()
    
    /// Formaterer en dato med norsk format: "14.12.2025"
    static func format(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
}
