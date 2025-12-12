import Foundation

struct WarrantyService {
    func defaultWarrantyYears(for category: Category) -> Int {
        switch category {
        case .electronics: return 5
        case .clothes: return 2
        case .groceries: return 0
        case .sports: return 2
        case .transport: return 2
        case .other: return 1
        }
    }

    func expiryDate(from purchaseDate: Date, warrantyYears: Int) -> Date? {
        guard warrantyYears > 0 else { return nil }
        return Calendar.current.date(byAdding: .year, value: warrantyYears, to: purchaseDate)
    }
}
