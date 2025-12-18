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
        let normalized = storeName.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        
        // Try exact match first
        if let category = fuzzyMatch(storeName: normalized) {
            return category.category
        }
        
        // Fallback to keyword-based matching
        return keywordBasedCategory(for: normalized)
    }
    
    private func fuzzyMatch(storeName: String) -> (category: Category, score: Double)? {
        var bestMatch: (category: Category, score: Double)?
        
        for (key, category) in mapping {
            let normalizedKey = key.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            
            // Exact match gets highest score
            if storeName == normalizedKey {
                return (category, 1.0)
            }
            
            // Contains match gets medium score
            if storeName.contains(normalizedKey) || normalizedKey.contains(storeName) {
                let score = min(Double(storeName.count) / Double(normalizedKey.count),
                               Double(normalizedKey.count) / Double(storeName.count))
                if bestMatch == nil || score > bestMatch!.score {
                    bestMatch = (category, score)
                }
            }
            
            // Partial match (common substring) gets lower score
            let commonLength = longestCommonSubstring(storeName, normalizedKey).count
            if commonLength >= 3 {
                let score = Double(commonLength) / Double(max(storeName.count, normalizedKey.count)) * 0.5
                if bestMatch == nil || score > bestMatch!.score {
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
