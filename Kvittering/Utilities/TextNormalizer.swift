import Foundation

/// Utility for å normalisere tekst fra OCR og brukerinput
struct TextNormalizer {
    
    /// Normaliserer butikknavn med kapitalisering og korreksjon av norske bokstaver
    /// - Parameter text: Rå tekst fra OCR eller brukerinput
    /// - Returns: Normalisert butikknavn med stor bokstav i starten av hvert ord
    static func normalizeStoreName(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        
        // Først: Korriger norske bokstaver basert på vanlige OCR-feil
        let corrected = correctNorwegianCharacters(trimmed)
        
        // Deretter: Kapitaliser første bokstav i hvert ord
        return capitalizeWords(corrected)
    }
    
    /// Normaliserer produktnavn med kapitalisering
    /// - Parameter text: Rå tekst fra OCR eller brukerinput
    /// - Returns: Normalisert produktnavn med stor bokstav i starten
    static func normalizeProductName(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        
        // Kapitaliser første bokstav i hvert ord
        return capitalizeWords(trimmed)
    }
    
    /// Korrigerer vanlige OCR-feil med norske bokstaver
    /// - Parameter text: Tekst som kan inneholde OCR-feil
    /// - Returns: Tekst med korrigerte norske bokstaver
    static func correctNorwegianCharacters(_ text: String) -> String {
        var result = text
        
        // Regel 1: aa → å (vanlig OCR-feil for å)
        result = result.replacingOccurrences(of: "aa", with: "å", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "Aa", with: "Å")
        result = result.replacingOccurrences(of: "AA", with: "Å")
        
        // Regel 2: ae → æ (vanlig OCR-feil for æ)
        result = result.replacingOccurrences(of: "ae", with: "æ", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "Ae", with: "Æ")
        result = result.replacingOccurrences(of: "AE", with: "Æ")
        
        // Regel 3: oe → ø (vanlig OCR-feil for ø)
        result = result.replacingOccurrences(of: "oe", with: "ø", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "Oe", with: "Ø")
        result = result.replacingOccurrences(of: "OE", with: "Ø")
        
        // Regel 4 (fjernet): O/0 → ø var for aggressiv og konverterte gyldige "o" til "ø"
        // (f.eks. "Sport" → "Spørt"). O/0 → ø er en sjelden OCR-feil i moderne OCR-systemer.
        
        return result
    }
    
    /// Kapitaliserer første bokstav i hvert ord
    /// - Parameter text: Tekst som skal kapitaliseres
    /// - Returns: Tekst med stor bokstav i starten av hvert ord
    static func capitalizeWords(_ text: String) -> String {
        // Split tekst i ord, kapitaliser hvert ord, og join igjen
        let words = text.components(separatedBy: .whitespaces)
        let capitalized = words.map { word in
            guard !word.isEmpty else { return word }
            
            // Behold spesialtegn som &, -, etc. i starten
            guard let firstChar = word.first else {
                return word
            }
            var result = word
            
            if firstChar.isLetter {
                // Kapitaliser første bokstav
                let first = String(firstChar).uppercased()
                let rest = String(result.dropFirst())
                result = first + rest
            }
            
            return result
        }
        
        return capitalized.joined(separator: " ")
    }
    
    /// Normaliserer tekst ved å fjerne ekstra whitespace og normalisere linjeskift
    /// - Parameter text: Tekst som skal normaliseres
    /// - Returns: Normalisert tekst
    static func normalizeWhitespace(_ text: String) -> String {
        return text
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

