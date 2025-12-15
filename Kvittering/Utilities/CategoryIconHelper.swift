import Foundation

/// Utility for å hente ikoner for kategorier
struct CategoryIconHelper {
    /// Henter SF Symbol-navn for en kategori basert på kategori-streng
    /// - Parameter category: Kategori-streng (f.eks. "Mat og dagligvare", "Klær")
    /// - Returns: SF Symbol-navn for kategorien, eller "tag" som fallback
    static func icon(for category: String) -> String {
        let cat = Category.migrate(category)
        return icon(for: cat)
    }
    
    /// Henter SF Symbol-navn for en kategori
    /// - Parameter category: Category enum-verdi
    /// - Returns: SF Symbol-navn for kategorien
    static func icon(for category: Category) -> String {
        switch category {
        case .groceries: return "cart.fill"
        case .electronics: return "iphone"
        case .sports: return "figure.run"
        case .clothes: return "tshirt.fill"
        case .construction: return "hammer.fill"
        case .other: return "tag"
        }
    }
}

