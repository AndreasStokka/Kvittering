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
        // #region agent log
        let logData: [String: Any] = [
            "sessionId": "debug-session",
            "runId": "run1",
            "hypothesisId": "C",
            "location": "EditReceiptViewModel.swift:41",
            "message": "attachContext kalt",
            "data": ["hasContext": true],
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        if let logJson = try? JSONSerialization.data(withJSONObject: logData),
           let logString = String(data: logJson, encoding: .utf8) {
            if let existingLog = try? String(contentsOfFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", encoding: .utf8) {
                try? (existingLog + "\n" + logString).write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
            } else {
                try? logString.write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
            }
        }
        // #endregion
        
        self.repository = ReceiptRepository(context: context)
        
        // #region agent log
        let logData2: [String: Any] = [
            "sessionId": "debug-session",
            "runId": "run1",
            "hypothesisId": "C",
            "location": "EditReceiptViewModel.swift:60",
            "message": "Repository opprettet",
            "data": ["hasRepository": repository != nil],
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        if let logJson = try? JSONSerialization.data(withJSONObject: logData2),
           let logString = String(data: logJson, encoding: .utf8),
           let existingLog = try? String(contentsOfFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", encoding: .utf8) {
            try? (existingLog + "\n" + logString).write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
        }
        // #endregion
    }

    func applyOCR(result: OCRResult) {
        if let store = result.storeName { storeName = store }
        if let date = result.purchaseDate { purchaseDate = date }
        if let total = result.totalAmount { totalAmount = total }
        if !result.lineItems.isEmpty { lineItems = result.lineItems }
        category = categoryService.suggestedCategory(for: storeName)
        warrantyYears = warrantyService.defaultWarrantyYears(for: category)
    }

    func save() throws {
        // #region agent log
        let logData: [String: Any] = [
            "sessionId": "debug-session",
            "runId": "run1",
            "hypothesisId": "D",
            "location": "EditReceiptViewModel.swift:54",
            "message": "save() startet",
            "data": [
                "hasRepository": repository != nil,
                "storeName": storeName,
                "totalAmount": "\(totalAmount)",
                "isEditing": editingReceipt != nil
            ],
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        if let logJson = try? JSONSerialization.data(withJSONObject: logData),
           let logString = String(data: logJson, encoding: .utf8) {
            if let existingLog = try? String(contentsOfFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", encoding: .utf8) {
                try? (existingLog + "\n" + logString).write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
            } else {
                try? logString.write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
            }
        }
        // #endregion
        
        guard let repository else {
            // #region agent log
            let logData2: [String: Any] = [
                "sessionId": "debug-session",
                "runId": "run1",
                "hypothesisId": "D",
                "location": "EditReceiptViewModel.swift:85",
                "message": "Repository er nil",
                "data": [:],
                "timestamp": Int(Date().timeIntervalSince1970 * 1000)
            ]
            if let logJson = try? JSONSerialization.data(withJSONObject: logData2),
               let logString = String(data: logJson, encoding: .utf8),
               let existingLog = try? String(contentsOfFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", encoding: .utf8) {
                try? (existingLog + "\n" + logString).write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
            }
            // #endregion
            
            throw NSError(domain: "EditReceiptViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ModelContext er ikke tilkoblet"])
        }
        
        // Validering
        guard !storeName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NSError(domain: "EditReceiptViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Butikknavn er påkrevd"])
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
