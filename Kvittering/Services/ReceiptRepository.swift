import Foundation
import SwiftData

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
        var predicates: [Predicate<Receipt>] = []

        if let category {
            predicates.append(#Predicate<Receipt> { $0.category == category.rawValue })
        }

        if !searchText.isEmpty {
            let text = searchText.lowercased()
            predicates.append(#Predicate<Receipt> { receipt in
                receipt.storeName.lowercased().contains(text)
            })
        }

        if let dateRange {
            predicates.append(#Predicate<Receipt> { receipt in
                dateRange.contains(receipt.purchaseDate)
            })
        }

        if !predicates.isEmpty {
            descriptor.predicate = predicates.reduce(Predicate.alwaysTrue) { partial, next in
                #Predicate<Receipt> { receipt in
                    partial.evaluate(receipt) && next.evaluate(receipt)
                }
            }
        }

        return (try? context.fetch(descriptor)) ?? []
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
