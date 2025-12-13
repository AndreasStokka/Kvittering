import Foundation
import SwiftData
import UIKit

@MainActor
final class ReceiptRepository {
    private let context: ModelContext
    private let imageStore: ImageStore

    init(context: ModelContext, imageStore: ImageStore = ImageStore()) {
        self.context = context
        self.imageStore = imageStore
    }

    func fetchReceipts(category: Category? = nil, searchText: String = "", dateRange: ClosedRange<Date>? = nil) -> [Receipt] {
        var descriptor = FetchDescriptor<Receipt>(sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)])

        // Build predicate based on what filters are provided
        if let category {
            let categoryValue = category.rawValue
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                if let dateRange {
                    let startDate = dateRange.lowerBound
                    let endDate = dateRange.upperBound
                    descriptor.predicate = #Predicate<Receipt> { receipt in
                        receipt.category == categoryValue && receipt.storeName.localizedStandardContains(searchLower) && receipt.purchaseDate >= startDate && receipt.purchaseDate <= endDate
                    }
                } else {
                    descriptor.predicate = #Predicate<Receipt> { receipt in
                        receipt.category == categoryValue && receipt.storeName.localizedStandardContains(searchLower)
                    }
                }
            } else if let dateRange {
                let startDate = dateRange.lowerBound
                let endDate = dateRange.upperBound
                descriptor.predicate = #Predicate<Receipt> { receipt in
                    receipt.category == categoryValue && receipt.purchaseDate >= startDate && receipt.purchaseDate <= endDate
                }
            } else {
                descriptor.predicate = #Predicate<Receipt> { receipt in
                    receipt.category == categoryValue
                }
            }
        } else if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            if let dateRange {
                let startDate = dateRange.lowerBound
                let endDate = dateRange.upperBound
                descriptor.predicate = #Predicate<Receipt> { receipt in
                    receipt.storeName.localizedStandardContains(searchLower) && receipt.purchaseDate >= startDate && receipt.purchaseDate <= endDate
                }
            } else {
                descriptor.predicate = #Predicate<Receipt> { receipt in
                    receipt.storeName.localizedStandardContains(searchLower)
                }
            }
        } else if let dateRange {
            let startDate = dateRange.lowerBound
            let endDate = dateRange.upperBound
            descriptor.predicate = #Predicate<Receipt> { receipt in
                receipt.purchaseDate >= startDate && receipt.purchaseDate <= endDate
            }
        }

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Feil ved henting av kvitteringer: \(error.localizedDescription)")
            return []
        }
    }

    func add(receipt: Receipt, image: UIImage?) throws {
        if let image, let storedPath = try? imageStore.saveImage(image, id: receipt.id) {
            receipt.imagePath = storedPath
        }
        context.insert(receipt)
        try context.save()
    }

    func update(_ receipt: Receipt) throws {
        try context.save()
    }

    func delete(_ receipt: Receipt) throws {
        imageStore.deleteImage(path: receipt.imagePath)
        context.delete(receipt)
        try context.save()
    }

    func deleteAll() throws {
        let receipts = try context.fetch(FetchDescriptor<Receipt>())
        receipts.forEach { imageStore.deleteImage(path: $0.imagePath) }
        receipts.forEach { context.delete($0) }
        try context.save()
    }
}
