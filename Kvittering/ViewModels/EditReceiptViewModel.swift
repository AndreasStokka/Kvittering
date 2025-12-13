import Foundation
import SwiftData
import SwiftUI

@MainActor
final class EditReceiptViewModel: ObservableObject {
    @Published var storeName: String = ""
    @Published var purchaseDate: Date = Date()
    @Published var totalAmount: Decimal = 0
    @Published var category: Category = .other
    @Published var hasWarranty: Bool = true
    @Published var warrantyYears: Int = 1
    @Published var lineItems: [LineItem] = []
    @Published var note: String = ""
    @Published var image: UIImage?

    private var repository: ReceiptRepository?
    private let categoryService: CategoryService
    private let warrantyService: WarrantyService
    private let ownerId: String
    private var editingReceipt: Receipt?

    init(ownerId: String = "local-user", receipt: Receipt? = nil) {
        self.categoryService = CategoryService()
        self.warrantyService = WarrantyService()
        self.ownerId = ownerId
        self.editingReceipt = receipt

        if let receipt {
            storeName = receipt.storeName
            purchaseDate = receipt.purchaseDate
            totalAmount = receipt.totalAmount
            category = Category(rawValue: receipt.category) ?? .other
            hasWarranty = receipt.hasWarranty
            warrantyYears = receipt.warrantyYears
            lineItems = receipt.lineItems
            note = receipt.note ?? ""
        }
    }

    func attachContext(_ context: ModelContext) {
        self.repository = ReceiptRepository(context: context)
    }

    func applyOCR(result: OCRResult) {
        if let store = result.storeName { storeName = store }
        if let date = result.purchaseDate { purchaseDate = date }
        if let total = result.totalAmount {
            // Valider at beløpet ikke er NaN eller ugyldig
            guard !total.isNaN && !total.isInfinite && total > 0 else {
                return // Ikke sett ugyldig beløp
            }
            totalAmount = total
        }
        if !result.lineItems.isEmpty { lineItems = result.lineItems }
        category = categoryService.suggestedCategory(for: storeName)
        warrantyYears = warrantyService.defaultWarrantyYears(for: category)
    }

    func save() throws {
        guard let repository else {
            throw NSError(domain: "EditReceiptViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ModelContext er ikke tilkoblet"])
        }
        
        guard !storeName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NSError(domain: "EditReceiptViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Butikknavn er påkrevd"])
        }
        
        // Valider at beløpet ikke er NaN eller ugyldig
        guard !totalAmount.isNaN && !totalAmount.isInfinite else {
            throw NSError(domain: "EditReceiptViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Beløpet er ugyldig"])
        }
        
        guard totalAmount > 0 else {
            throw NSError(domain: "EditReceiptViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Beløpet må være større enn 0"])
        }
        
        let expiry = warrantyService.expiryDate(from: purchaseDate, warrantyYears: warrantyYears)

        if let editingReceipt {
            editingReceipt.storeName = storeName
            editingReceipt.purchaseDate = purchaseDate
            editingReceipt.totalAmount = totalAmount
            editingReceipt.category = category.rawValue
            editingReceipt.hasWarranty = hasWarranty
            editingReceipt.warrantyYears = warrantyYears
            editingReceipt.warrantyExpiryDate = expiry
            editingReceipt.lineItems = lineItems
            editingReceipt.note = note
            try repository.update(editingReceipt)
        } else {
            let receipt = Receipt(
                ownerId: ownerId,
                storeName: storeName,
                purchaseDate: purchaseDate,
                totalAmount: totalAmount,
                category: category.rawValue,
                hasWarranty: hasWarranty,
                warrantyYears: warrantyYears,
                warrantyExpiryDate: expiry,
                lineItems: lineItems,
                note: note
            )
            try repository.add(receipt: receipt, image: image)
            editingReceipt = receipt
        }
    }
}
