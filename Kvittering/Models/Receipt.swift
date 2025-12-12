import Foundation
import SwiftData

@Model
final class Receipt {
    @Attribute(.unique) var id: UUID
    var ownerId: String
    var storeName: String
    var purchaseDate: Date
    var totalAmount: Decimal
    var category: String
    var hasWarranty: Bool
    var warrantyYears: Int
    var warrantyExpiryDate: Date?
    var lineItems: [LineItem]
    var imagePath: String?
    var note: String?
    var hasReturnPolicy: Bool
    var returnDays: Int?
    var hasExchangePolicy: Bool
    var exchangeDays: Int?

    init(
        id: UUID = UUID(),
        ownerId: String,
        storeName: String,
        purchaseDate: Date,
        totalAmount: Decimal,
        category: String,
        hasWarranty: Bool,
        warrantyYears: Int,
        warrantyExpiryDate: Date?,
        lineItems: [LineItem] = [],
        imagePath: String? = nil,
        note: String? = nil,
        hasReturnPolicy: Bool = false,
        returnDays: Int? = nil,
        hasExchangePolicy: Bool = false,
        exchangeDays: Int? = nil
    ) {
        self.id = id
        self.ownerId = ownerId
        self.storeName = storeName
        self.purchaseDate = purchaseDate
        self.totalAmount = totalAmount
        self.category = category
        self.hasWarranty = hasWarranty
        self.warrantyYears = warrantyYears
        self.warrantyExpiryDate = warrantyExpiryDate
        self.lineItems = lineItems
        self.imagePath = imagePath
        self.note = note
        self.hasReturnPolicy = hasReturnPolicy
        self.returnDays = returnDays
        self.hasExchangePolicy = hasExchangePolicy
        self.exchangeDays = exchangeDays
    }
}

@Model
final class LineItem {
    @Attribute(.unique) var id: UUID
    var descriptionText: String
    var quantity: Decimal
    var unitPrice: Decimal
    var lineTotal: Decimal

    init(
        id: UUID = UUID(),
        descriptionText: String,
        quantity: Decimal,
        unitPrice: Decimal,
        lineTotal: Decimal
    ) {
        self.id = id
        self.descriptionText = descriptionText
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.lineTotal = lineTotal
    }
}

enum Category: String, CaseIterable, Identifiable {
    case groceries = "Mat"
    case clothes = "Klær"
    case electronics = "Elektronikk"
    case sports = "Sport"
    case transport = "Transport"
    case other = "Annet"

    var id: String { rawValue }
}
