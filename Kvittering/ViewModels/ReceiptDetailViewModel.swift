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
        // Repository vil bli satt i attach()
    }

    func attach(context: ModelContext) {
        // keep same imageStore
        self.repository = ReceiptRepository(context: context, imageStore: imageStore)
    }

    var warrantyStatusText: String {
        guard receipt.hasWarranty, let expiry = receipt.warrantyExpiryDate else { return "Ingen garanti" }
        return expiry > Date() ? "Garantien er gyldig" : "Garantien er utløpt"
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
        if let image = image() { items.append(image) }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "no_NO")
        formatter.dateStyle = .medium
        let text = "Kvittering: \(receipt.storeName) – \(formatter.string(from: receipt.purchaseDate)) – kr \(receipt.totalAmount)"
        items.append(text)
        shareItems = items
    }
}
