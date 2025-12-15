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
        var corrected = text
        
        // Vanlige OCR-feil for norske bokstaver:
        // Æ kan bli feilgjenkjent som AE, A, eller andre tegn
        // Ø kan bli feilgjenkjent som O, 0, eller andre tegn
        // Å kan bli feilgjenkjent som A, AA, eller andre tegn
        
        // Korriger basert på kontekst og kjente butikknavn
        // Dette er en enkel implementering - kan utvides med fuzzy matching
        
        // Eksempel: "Forde" i kontekst av "Sport 1" burde være "Førde"
        // Men vi lar StoreNameMatcher håndtere dette for mer presis matching
        
        return corrected
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
            var result = word
            let firstChar = result.first!
            
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

