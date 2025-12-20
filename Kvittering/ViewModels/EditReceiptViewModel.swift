import Foundation
import SwiftData
import SwiftUI

@MainActor
final class EditReceiptViewModel: ObservableObject {
    @Published var storeName: String = ""
    @Published var purchaseDate: Date = Date()
    @Published var totalAmount: Decimal = 0 {
        didSet {
            // Valider at beløpet ikke er NaN eller ugyldig
            if totalAmount.isNaN || totalAmount.isInfinite {
                totalAmount = 0
                totalAmountString = ""
                return
            }
            
            // Oppdater string-verdien når Decimal-verdien endres (f.eks. fra OCR)
            // Unngå loop ved å sjekke om string allerede er riktig
            let expectedString = formatAmountForEditing(totalAmount)
            if totalAmountString != expectedString {
                totalAmountString = expectedString
            }
        }
    }
    @Published var totalAmountString: String = ""
    @Published var category: Category = .other
    @Published var lineItems: [LineItem] = []
    @Published var note: String = ""
    @Published var image: UIImage?

    private var repository: ReceiptRepository?
    private let categoryService: CategoryService
    private let ownerId: String
    private var editingReceipt: Receipt?

    init(ownerId: String = "local-user", receipt: Receipt? = nil) {
        self.categoryService = CategoryService()
        self.ownerId = ownerId
        self.editingReceipt = receipt

        if let receipt {
            storeName = receipt.storeName
            purchaseDate = receipt.purchaseDate
            // Valider beløpet før tildeling
            let amount = receipt.totalAmount
            if amount.isNaN || amount.isInfinite {
                totalAmount = 0
                totalAmountString = ""
            } else {
                totalAmount = amount
                totalAmountString = formatAmountForEditing(amount)
            }
            category = Category.migrate(receipt.category)
            // Valider og filtrer ut ugyldige lineItems
            lineItems = receipt.lineItems.filter { item in
                !item.quantity.isNaN && !item.quantity.isInfinite &&
                !item.unitPrice.isNaN && !item.unitPrice.isInfinite &&
                !item.lineTotal.isNaN && !item.lineTotal.isInfinite &&
                item.quantity > 0 && item.unitPrice > 0 && item.lineTotal > 0
            }
            note = receipt.note ?? ""
        } else {
            totalAmountString = ""
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
            // totalAmountString oppdateres automatisk via didSet
        }
        if !result.lineItems.isEmpty {
            // Valider og filtrer ut ugyldige lineItems
            lineItems = result.lineItems.filter { item in
                !item.quantity.isNaN && !item.quantity.isInfinite &&
                !item.unitPrice.isNaN && !item.unitPrice.isInfinite &&
                !item.lineTotal.isNaN && !item.lineTotal.isInfinite &&
                item.quantity > 0 && item.unitPrice > 0 && item.lineTotal > 0
            }
        }
        category = categoryService.suggestedCategory(for: storeName)
    }
    
    /// Oppdaterer Decimal-verdien fra string-input
    func updateAmountFromString(_ string: String) {
        // Fjern mellomrom og normaliser komma/punktum
        let cleaned = string
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        
        // Prøv å parse som Decimal
        if let value = Decimal(string: cleaned), !value.isNaN && !value.isInfinite {
            // Unngå å trigge didSet i loop ved å sjekke om verdien faktisk endret seg
            let difference = totalAmount - value
            // Valider difference før konvertering
            if !difference.isNaN && !difference.isInfinite {
                let diffValue = NSDecimalNumber(decimal: difference).doubleValue
                if !diffValue.isNaN && !diffValue.isInfinite && abs(diffValue) > 0.01 {
                    totalAmount = value
                }
            } else {
                // Hvis difference er ugyldig, sett verdien direkte
                totalAmount = value
            }
        } else if cleaned.isEmpty || cleaned == "." || cleaned == "," {
            // Tillat tom string eller bare separator (brukeren sletter eller skriver)
            // Ikke sett til 0 her, la brukeren skrive ferdig
        }
    }
    
    /// Formaterer beløp for redigering (uten "kr" prefix)
    private func formatAmountForEditing(_ amount: Decimal) -> String {
        // Valider at beløpet ikke er NaN eller ugyldig
        guard !amount.isNaN && !amount.isInfinite else {
            return ""
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "nb_NO")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        
        // Konverter til NSDecimalNumber på en sikker måte
        let nsDecimal = NSDecimalNumber(decimal: amount)
        // NSDecimalNumber har ikke isNaN/isInfinite, så vi sjekker via doubleValue
        let doubleValue = nsDecimal.doubleValue
        guard !doubleValue.isNaN && !doubleValue.isInfinite else {
            return ""
        }
        
        guard let formatted = formatter.string(from: nsDecimal) else {
            return ""
        }
        return formatted
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

        // Normaliser butikknavn før lagring
        let normalizedStoreName = TextNormalizer.normalizeStoreName(storeName)
        
        // TODO: Enable in v1.1 - LineItems lagring deaktivert i v1.0
        // LineItems tolkes fortsatt i OCR for debugging og logges til konsollen
        // Aktiver denne koden når OCR-kvaliteten er god nok for produksjon
        let normalizedLineItems: [LineItem] = []
        // let normalizedLineItems = lineItems.map { item in
        //     LineItem(
        //         descriptionText: TextNormalizer.normalizeProductName(item.descriptionText),
        //         quantity: item.quantity,
        //         unitPrice: item.unitPrice,
        //         lineTotal: item.lineTotal
        //     )
        // }

        if let editingReceipt {
            editingReceipt.storeName = normalizedStoreName
            editingReceipt.purchaseDate = purchaseDate
            editingReceipt.totalAmount = totalAmount
            editingReceipt.category = category.rawValue
            editingReceipt.lineItems = normalizedLineItems
            editingReceipt.note = note
            try repository.update(editingReceipt)
        } else {
            let receipt = Receipt(
                ownerId: ownerId,
                storeName: normalizedStoreName,
                purchaseDate: purchaseDate,
                totalAmount: totalAmount,
                category: category.rawValue,
                lineItems: normalizedLineItems,
                note: note
            )
            try repository.add(receipt: receipt, image: image)
            editingReceipt = receipt
        }
    }
}
