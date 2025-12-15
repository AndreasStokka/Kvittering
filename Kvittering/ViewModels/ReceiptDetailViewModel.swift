import Foundation
import SwiftUI
import SwiftData

@MainActor
final class ReceiptDetailViewModel: ObservableObject {
    @Published var receipt: Receipt
    @Published var shareItems: [Any] = []

    private var repository: ReceiptRepository?
    private let imageStore: ImageStore

    init(receipt: Receipt, imageStore: ImageStore = ImageStore()) {
        self.receipt = receipt
        self.imageStore = imageStore
        
        // Valider og fikse ugyldige verdier i receipt (SwiftData @Model kan endres direkte)
        if receipt.totalAmount.isNaN || receipt.totalAmount.isInfinite {
            receipt.totalAmount = 0
        }
        
        // Filtrer ut ugyldige lineItems (må gjøres via en ny array og tilbake)
        let validLineItems = receipt.lineItems.filter { item in
            !item.quantity.isNaN && !item.quantity.isInfinite &&
            !item.unitPrice.isNaN && !item.unitPrice.isInfinite &&
            !item.lineTotal.isNaN && !item.lineTotal.isInfinite &&
            item.quantity > 0 && item.unitPrice > 0 && item.lineTotal > 0
        }
        
        // Hvis noen lineItems ble filtrert bort, oppdater receipt
        if validLineItems.count != receipt.lineItems.count {
            receipt.lineItems = validLineItems
        }
        
        // Repository vil bli satt i attach()
    }

    func attach(context: ModelContext) {
        // keep same imageStore
        self.repository = ReceiptRepository(context: context, imageStore: imageStore)
    }

    func image() -> UIImage? {
        guard let path = receipt.imagePath else { return nil }
        return imageStore.loadImage(path: path)
    }

    func delete() throws {
        guard let repository else {
            throw NSError(domain: "ReceiptDetailViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ModelContext er ikke tilkoblet"])
        }
        try repository.delete(receipt)
    }

    func prepareShare() {
        var items: [Any] = []
        
        // Share file URL instead of UIImage for better quality in emails/messages
        if let path = receipt.imagePath,
           let fileURL = imageStore.imageFileURL(path: path) {
            items.append(fileURL)
        }
        
        // Add text description
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "no_NO")
        formatter.dateStyle = .medium
        
        // Valider beløpet før konvertering
        let amount = receipt.totalAmount
        let amountString: String
        if amount.isNaN || amount.isInfinite {
            amountString = "0,00"
        } else {
            amountString = "\(NSDecimalNumber(decimal: amount))"
        }
        
        let text = "Kvittering: \(receipt.storeName) – \(formatter.string(from: receipt.purchaseDate)) – kr \(amountString)"
        items.append(text)
        
        shareItems = items
    }
    
    /// Beregner og returnerer en tekst som beskriver hvor lenge siden kvitteringen ble kjøpt
    var timeElapsedText: String {
        let calendar = Calendar.current
        let now = Date()
        let purchaseDate = receipt.purchaseDate
        
        // Sjekk om kjøpt i dag
        if calendar.isDateInToday(purchaseDate) {
            return "Kjøpt i dag"
        }
        
        // Sjekk om kjøpt i går
        if calendar.isDateInYesterday(purchaseDate) {
            return "Kjøpt i går"
        }
        
        // Beregn tidsforskjell
        let components = calendar.dateComponents([.year, .month, .day], from: purchaseDate, to: now)
        
        var parts: [String] = []
        if let years = components.year, years > 0 {
            parts.append("\(years) \(years == 1 ? "år" : "år")")
        }
        if let months = components.month, months > 0 {
            parts.append("\(months) \(months == 1 ? "måned" : "måneder")")
        }
        if let days = components.day, days > 0, parts.isEmpty {
            // Vis bare dager hvis vi ikke har år eller måneder
            parts.append("\(days) \(days == 1 ? "dag" : "dager")")
        }
        
        if parts.isEmpty {
            return "Kjøpt i dag"
        } else {
            return "Kjøpt for \(parts.joined(separator: " og ")) siden"
        }
    }
}
