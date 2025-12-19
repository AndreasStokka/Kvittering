import Foundation

class CategoryService {
    private let mapping: [String: Category]
    
    init() {
        self.mapping = Self.loadStoreMappings()
    }
    
    private static func loadStoreMappings() -> [String: Category] {
        guard let url = Bundle.main.url(forResource: "store_categories", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stores = json["stores"] as? [String: String] else {
            // Fallback to hardcoded mappings if JSON fails to load
            // Note: JSON file must be added to Xcode project and included in app bundle
            return [
                "rema": .groceries,
                "rema 1000": .groceries,
                "coop": .groceries,
                "meny": .groceries,
                "spar": .groceries,
                "power": .electronics,
                "elkjøp": .electronics,
                "xxl": .sports,
                "intersport": .sports,
                "byggmax": .construction,
                "jula": .construction
            ]
        }
        
        // Convert string category names to Category enum
        var result: [String: Category] = [:]
        for (storeKey, categoryString) in stores {
            if let category = Category.allCases.first(where: { $0.rawValue == categoryString }) {
                result[storeKey] = category
            }
        }
        return result
    }
    
    func suggestedCategory(for storeName: String) -> Category {
        // Early return for empty strings
        guard !storeName.isEmpty else {
            return .other
        }
        
        let normalized = storeName.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        
        // Try exact match first
        if let category = fuzzyMatch(storeName: normalized) {
            return category.category
        }
        
        // Fallback to keyword-based matching
        return keywordBasedCategory(for: normalized)
    }
    
    private func fuzzyMatch(storeName: String) -> (category: Category, score: Double)? {
        // Early return for empty strings
        guard !storeName.isEmpty else {
            return nil
        }
        
        var bestMatch: (category: Category, score: Double)?
        
        // Sort keys by length (longest first) to prioritize more specific matches
        // e.g., "coop extra" should be evaluated before "coop"
        let sortedKeys = mapping.keys.sorted { $0.count > $1.count }
        
        for key in sortedKeys {
            guard let category = mapping[key] else { continue }
            let normalizedKey = key.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            
            // Exact match gets highest score
            if storeName == normalizedKey {
                return (category, 1.0)
            }
            
            // Contains match gets medium score
            if storeName.contains(normalizedKey) {
                let score = min(Double(storeName.count) / Double(normalizedKey.count),
                               Double(normalizedKey.count) / Double(storeName.count))
                if let currentBest = bestMatch {
                    if score > currentBest.score {
                        bestMatch = (category, score)
                    }
                } else {
                    bestMatch = (category, score)
                }
                // Skip longestCommonSubstring for contains matches - they're already handled
                continue
            }
            
            // Only check longestCommonSubstring if we haven't found a contains match yet
            // This prevents shorter keys from overriding longer contains matches
            let commonLength = longestCommonSubstring(storeName, normalizedKey).count
            if commonLength >= 3 {
                let score = Double(commonLength) / Double(max(storeName.count, normalizedKey.count)) * 0.5
                if let currentBest = bestMatch {
                    if score > currentBest.score {
                        bestMatch = (category, score)
                    }
                } else {
                    bestMatch = (category, score)
                }
            }
        }
        
        // Only return if score is above threshold
        if let match = bestMatch, match.score >= 0.3 {
            return match
        }
        
        return nil
    }
    
    private func longestCommonSubstring(_ s1: String, _ s2: String) -> String {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        var maxLength = 0
        var endIndex = 0
        
        var dp = Array(repeating: Array(repeating: 0, count: s2.count + 1), count: s1.count + 1)
        
        for i in 1...s1.count {
            for j in 1...s2.count {
                if s1Array[i-1] == s2Array[j-1] {
                    dp[i][j] = dp[i-1][j-1] + 1
                    if dp[i][j] > maxLength {
                        maxLength = dp[i][j]
                        endIndex = i
                    }
                }
            }
        }
        
        if maxLength > 0 {
            let start = s1.index(s1.startIndex, offsetBy: endIndex - maxLength)
            let end = s1.index(s1.startIndex, offsetBy: endIndex)
            return String(s1[start..<end])
        }
        
        return ""
    }
    
    private func keywordBasedCategory(for storeName: String) -> Category {
        let keywords: [(String, Category)] = [
            ("apotek", .other),
            ("mat", .groceries),
            ("dagligvare", .groceries),
            ("supermarked", .groceries),
            ("cafe", .groceries),
            ("kafé", .groceries),
            ("elektronikk", .electronics),
            ("elektronik", .electronics),
            ("data", .electronics),
            ("pc", .electronics),
            ("mobil", .electronics),
            ("sport", .sports),
            ("idrett", .sports),
            ("klær", .clothes),
            ("dress", .clothes),
            ("mote", .clothes),
            ("bygg", .construction),
            ("anlegg", .construction),
            ("hage", .construction),
            ("jernia", .construction),
            ("maxbo", .construction),
            ("biltema", .construction),
            ("mekonomen", .construction)
        ]
        
        for (keyword, category) in keywords {
            if storeName.contains(keyword) {
                return category
            }
        }
        
        return .other
    }
}
