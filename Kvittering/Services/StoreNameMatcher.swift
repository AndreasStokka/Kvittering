import Foundation

/// Service for å matche og korrigere butikknavn basert på kjente butikknavn
class StoreNameMatcher {
    private let knownStoreNames: [String]
    
    init() {
        self.knownStoreNames = Self.loadKnownStoreNames()
    }
    
    /// Laster kjente butikknavn fra store_categories.json
    private static func loadKnownStoreNames() -> [String] {
        guard let url = Bundle.main.url(forResource: "store_categories", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stores = json["stores"] as? [String: String] else {
            // Fallback til hardkodede navn hvis JSON ikke kan lastes
            return [
                "rema", "kiwi", "coop", "extra", "meny", "bunnpris", "spar", "joker", "prix",
                "sport 1", "xxl", "intersport", "g-sport", "anton sport",
                "elkjøp", "power", "komplett", "netonnet",
                "byggmax", "jula", "europris", "clas ohlson", "jernia", "maxbo", "montér",
                "h&m", "cubus", "dressmann", "bikbok", "carlings", "volt",
                "apotek 1", "boots", "vitus", "vinmonopolet",
                "circle k", "esso", "shell", "uno-x", "best"
            ]
        }
        
        return Array(stores.keys)
    }
    
    /// Matcher og korrigerer butikknavn basert på fuzzy matching
    /// - Parameter text: Rå tekst fra OCR eller brukerinput
    /// - Returns: Korrigert butikknavn hvis match funnet, ellers nil
    func matchAndCorrect(_ text: String) -> String? {
        // Korriger norske bokstaver først
        let corrected = TextNormalizer.correctNorwegianCharacters(text)
        let normalized = corrected.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        let trimmed = corrected.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Først: Prøv eksakt match (case-insensitive, diacritic-insensitive)
        for knownStore in knownStoreNames {
            let knownNormalized = knownStore.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            
            if normalized == knownNormalized {
                // Returner originalt kjent navn (med korrekte norske bokstaver)
                return TextNormalizer.normalizeStoreName(knownStore)
            }
        }
        
        // Deretter: Prøv fuzzy matching
        if let bestMatch = fuzzyMatch(text: normalized) {
            return TextNormalizer.normalizeStoreName(bestMatch)
        }
        
        // Sjekk om tekst inneholder et kjent butikknavn
        for knownStore in knownStoreNames {
            let knownNormalized = knownStore.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            
            // Hvis tekst inneholder kjent navn, ekstraher det
            if normalized.contains(knownNormalized) || knownNormalized.contains(normalized) {
                // Prøv å ekstrahere butikknavnet fra linjen
                if let extracted = extractStoreName(from: trimmed, matching: knownStore) {
                    return TextNormalizer.normalizeStoreName(extracted)
                }
                return TextNormalizer.normalizeStoreName(knownStore)
            }
        }
        
        return nil
    }
    
    /// Fuzzy matching av butikknavn
    /// - Parameter text: Normalisert tekst (lowercase, diacritic-insensitive)
    /// - Returns: Beste match hvis score er over terskel
    private func fuzzyMatch(text: String) -> String? {
        var bestMatch: (name: String, score: Double)?
        
        for knownStore in knownStoreNames {
            let knownNormalized = knownStore.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            
            // Beregn likhetsscore
            let score = calculateSimilarity(text, knownNormalized)
            
            if score > 0.7 { // Terskel for akseptabel match
                if let currentBest = bestMatch {
                    if score > currentBest.score {
                        bestMatch = (knownStore, score)
                    }
                } else {
                    bestMatch = (knownStore, score)
                }
            }
        }
        
        return bestMatch?.name
    }
    
    /// Beregner likhet mellom to strenger
    /// - Parameters:
    ///   - s1: Første streng
    ///   - s2: Andre streng
    /// - Returns: Likhetsscore mellom 0.0 og 1.0
    private func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
        // Bruk Levenshtein distance for å beregne likhet
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        
        if maxLength == 0 {
            return 1.0
        }
        
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    /// Beregner Levenshtein distance mellom to strenger
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        // Initialize base cases
        for i in 0...m {
            dp[i][0] = i
        }
        for j in 0...n {
            dp[0][j] = j
        }
        
        // Fill the dp table
        for i in 1...m {
            for j in 1...n {
                if s1Array[i-1] == s2Array[j-1] {
                    dp[i][j] = dp[i-1][j-1]
                } else {
                    dp[i][j] = min(
                        dp[i-1][j] + 1,      // deletion
                        dp[i][j-1] + 1,      // insertion
                        dp[i-1][j-1] + 1    // substitution
                    )
                }
            }
        }
        
        return dp[m][n]
    }
    
    /// Ekstraherer butikknavn fra en linje som kan inneholde ekstra tekst
    /// - Parameters:
    ///   - line: Hele linjen fra OCR
    ///   - matching: Kjent butikknavn som matcher
    /// - Returns: Ekstrahert butikknavn hvis funnet
    private func extractStoreName(from line: String, matching knownStore: String) -> String? {
        let lineLower = line.lowercased()
        let knownLower = knownStore.lowercased()
        
        // Prøv å finne butikknavnet i linjen
        if let range = lineLower.range(of: knownLower) {
            // Hvis kjent navn er i starten av linjen, returner det
            if range.lowerBound == lineLower.startIndex {
                // Prøv å finne hvor navnet slutter (før eventuelle tall eller adresser)
                let startIndex = line.startIndex
                let endIndex = line.index(startIndex, offsetBy: knownStore.count)
                let extracted = String(line[startIndex..<endIndex])
                return extracted.trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Hvis ikke, returner hele linjen hvis den er kort nok
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.count <= 50 && trimmed.lowercased().contains(knownLower) {
            return trimmed
        }
        
        return nil
    }
}





