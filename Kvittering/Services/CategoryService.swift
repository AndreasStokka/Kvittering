import Foundation

struct CategoryService {
    private let mapping: [String: Category] = [
        "rema": .groceries,
        "coop": .groceries,
        "meny": .groceries,
        "power": .electronics,
        "elkjøp": .electronics,
        "xxl": .sports,
        "intersport": .sports,
        "flytoget": .transport
    ]

    func suggestedCategory(for storeName: String) -> Category {
        let lower = storeName.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        for (key, category) in mapping {
            if lower.contains(key) {
                return category
            }
        }
        return .other
    }
}
