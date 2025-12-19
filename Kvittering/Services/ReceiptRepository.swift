import Foundation
import SwiftData
import UIKit
import os.log

struct SearchFilters {
    var category: Category?
    var searchText: String = ""
    var searchScope: SearchScope = .storeName
    var dateRange: ClosedRange<Date>?
    var amountRange: ClosedRange<Decimal>?
}

enum SearchScope: String, CaseIterable {
    case storeName = "Butikknavn"
    case lineItems = "Varelinjer"
    case all = "Alle"
}

@MainActor
final class ReceiptRepository {
    private let context: ModelContext
    private let imageStore: ImageStore
    private static let logger = Logger(subsystem: "com.example.Kvittering", category: "ReceiptRepository")

    init(context: ModelContext, imageStore: ImageStore = ImageStore()) {
        self.context = context
        self.imageStore = imageStore
    }

    func fetchReceipts(filters: SearchFilters) -> [Receipt] {
        return fetchReceipts(
            category: filters.category,
            searchText: filters.searchText,
            searchScope: filters.searchScope,
            dateRange: filters.dateRange,
            amountRange: filters.amountRange
        )
    }
    
    func fetchReceipts(category: Category? = nil, searchText: String = "", searchScope: SearchScope = .storeName, dateRange: ClosedRange<Date>? = nil, amountRange: ClosedRange<Decimal>? = nil) -> [Receipt] {
        var descriptor = FetchDescriptor<Receipt>(sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)])

        // Bygg predikat basert på aktive filtre
        // SwiftData krever at alle betingelser er i #Predicate makroen, så vi må håndtere alle kombinasjoner
        let categoryValue = category?.rawValue
        let hasSearch = !searchText.isEmpty
        let searchLower = searchText.lowercased()
        let hasDateRange = dateRange != nil
        let startDate = dateRange?.lowerBound
        let endDate = dateRange?.upperBound
        let hasAmountRange = amountRange != nil
        let minAmount = amountRange?.lowerBound
        let maxAmount = amountRange?.upperBound
        
        // Bygg predikat basert på hvilke filtre som er aktive
        // Vi bruker en mer strukturert tilnærming for å redusere duplisering
        descriptor.predicate = buildPredicate(
            categoryValue: categoryValue,
            hasSearch: hasSearch,
            searchLower: searchLower,
            hasDateRange: hasDateRange,
            startDate: startDate,
            endDate: endDate,
            hasAmountRange: hasAmountRange,
            minAmount: minAmount,
            maxAmount: maxAmount
        )

        var results: [Receipt] = []
        do {
            results = try context.fetch(descriptor)
        } catch {
            Self.logger.error("Feil ved henting av kvitteringer: \(error.localizedDescription)")
            return []
        }
        
        // Bruk in-memory filtre for varelinjer-søk (SwiftData-begrensning)
        results = applyInMemoryFilters(
            results: results,
            searchText: searchText,
            searchScope: searchScope
        )
        
        return results
    }
    
    /// Bygger et SwiftData predikat basert på aktive filtre
    /// - Note: SwiftData's #Predicate makro krever eksplisitte kombinasjoner, så vi må håndtere alle mulige kombinasjoner
    private func buildPredicate(
        categoryValue: String?,
        hasSearch: Bool,
        searchLower: String,
        hasDateRange: Bool,
        startDate: Date?,
        endDate: Date?,
        hasAmountRange: Bool,
        minAmount: Decimal?,
        maxAmount: Decimal?
    ) -> Predicate<Receipt>? {
        // Håndter alle mulige kombinasjoner av filtre
        // Dette er nødvendig fordi SwiftData's #Predicate makro ikke støtter dynamisk predikat-bygging
        
        switch (categoryValue != nil, hasSearch, hasDateRange, hasAmountRange) {
        case (true, true, true, true):
            // Alle filtre
            guard let categoryValue, let startDate, let endDate, let minAmount, let maxAmount else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.category == categoryValue &&
                receipt.storeName.localizedStandardContains(searchLower) &&
                receipt.purchaseDate >= startDate && receipt.purchaseDate <= endDate &&
                receipt.totalAmount >= minAmount && receipt.totalAmount <= maxAmount
            }
            
        case (true, true, true, false):
            // Kategori + søk + dato
            guard let categoryValue, let startDate, let endDate else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.category == categoryValue &&
                receipt.storeName.localizedStandardContains(searchLower) &&
                receipt.purchaseDate >= startDate && receipt.purchaseDate <= endDate
            }
            
        case (true, true, false, true):
            // Kategori + søk + beløp
            guard let categoryValue, let minAmount, let maxAmount else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.category == categoryValue &&
                receipt.storeName.localizedStandardContains(searchLower) &&
                receipt.totalAmount >= minAmount && receipt.totalAmount <= maxAmount
            }
            
        case (true, false, true, true):
            // Kategori + dato + beløp
            guard let categoryValue, let startDate, let endDate, let minAmount, let maxAmount else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.category == categoryValue &&
                receipt.purchaseDate >= startDate && receipt.purchaseDate <= endDate &&
                receipt.totalAmount >= minAmount && receipt.totalAmount <= maxAmount
            }
            
        case (false, true, true, true):
            // Søk + dato + beløp
            guard let startDate, let endDate, let minAmount, let maxAmount else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.storeName.localizedStandardContains(searchLower) &&
                receipt.purchaseDate >= startDate && receipt.purchaseDate <= endDate &&
                receipt.totalAmount >= minAmount && receipt.totalAmount <= maxAmount
            }
            
        case (true, true, false, false):
            // Kategori + søk
            guard let categoryValue else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.category == categoryValue &&
                receipt.storeName.localizedStandardContains(searchLower)
            }
            
        case (true, false, true, false):
            // Kategori + dato
            guard let categoryValue, let startDate, let endDate else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.category == categoryValue &&
                receipt.purchaseDate >= startDate && receipt.purchaseDate <= endDate
            }
            
        case (true, false, false, true):
            // Kategori + beløp
            guard let categoryValue, let minAmount, let maxAmount else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.category == categoryValue &&
                receipt.totalAmount >= minAmount && receipt.totalAmount <= maxAmount
            }
            
        case (false, true, true, false):
            // Søk + dato
            guard let startDate, let endDate else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.storeName.localizedStandardContains(searchLower) &&
                receipt.purchaseDate >= startDate && receipt.purchaseDate <= endDate
            }
            
        case (false, true, false, true):
            // Søk + beløp
            guard let minAmount, let maxAmount else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.storeName.localizedStandardContains(searchLower) &&
                receipt.totalAmount >= minAmount && receipt.totalAmount <= maxAmount
            }
            
        case (false, false, true, true):
            // Dato + beløp
            guard let startDate, let endDate, let minAmount, let maxAmount else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.purchaseDate >= startDate && receipt.purchaseDate <= endDate &&
                receipt.totalAmount >= minAmount && receipt.totalAmount <= maxAmount
            }
            
        case (true, false, false, false):
            // Kun kategori
            guard let categoryValue else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.category == categoryValue
            }
            
        case (false, true, false, false):
            // Kun søk
            return #Predicate<Receipt> { receipt in
                receipt.storeName.localizedStandardContains(searchLower)
            }
            
        case (false, false, true, false):
            // Kun dato
            guard let startDate, let endDate else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.purchaseDate >= startDate && receipt.purchaseDate <= endDate
            }
            
        case (false, false, false, true):
            // Kun beløp
            guard let minAmount, let maxAmount else { return nil }
            return #Predicate<Receipt> { receipt in
                receipt.totalAmount >= minAmount && receipt.totalAmount <= maxAmount
            }
            
        default:
            // Ingen filtre
            return nil
        }
    }
    
    /// Bruker in-memory filtre for søk i varelinjer (SwiftData-begrensning)
    private func applyInMemoryFilters(
        results: [Receipt],
        searchText: String,
        searchScope: SearchScope
    ) -> [Receipt] {
        guard !searchText.isEmpty else { return results }
        
        switch searchScope {
        case .lineItems:
            return results.filter { receipt in
                receipt.lineItems.contains { item in
                    item.descriptionText.localizedCaseInsensitiveContains(searchText)
                }
            }
        case .all:
            return results.filter { receipt in
                receipt.storeName.localizedCaseInsensitiveContains(searchText) ||
                receipt.lineItems.contains { item in
                    item.descriptionText.localizedCaseInsensitiveContains(searchText)
                }
            }
        case .storeName:
            // Dette håndteres allerede i predikatet
            return results
        }
    }

    func add(receipt: Receipt, image: UIImage?) throws {
        // #region agent log
        let logPath = "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log"
        let logURL = URL(fileURLWithPath: logPath)
        let saveToPhoto = UserDefaults.standard.bool(forKey: "saveReceiptsToPhotoLibrary")
        Self.logger.debug("ReceiptRepository.add() called - hasImage: \(image != nil), saveToPhotoLibrary: \(saveToPhoto)")
        
        let repoLogData: [String: Any] = [
            "sessionId": "debug-session",
            "runId": "pre-fix",
            "hypothesisId": "H0",
            "location": "ReceiptRepository.swift:258",
            "message": "add() called",
            "data": [
                "hasImage": image != nil,
                "saveToPhotoLibrary": saveToPhoto
            ],
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: repoLogData), let jsonString = String(data: jsonData, encoding: .utf8) {
            // Ensure directory exists
            let logDir = logURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
            
            if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                defer { try? fileHandle.close() }
                _ = try? fileHandle.seekToEnd()
                if let data = (jsonString + "\n").data(using: .utf8) {
                    _ = try? fileHandle.write(contentsOf: data)
                }
            } else {
                try? (jsonString + "\n").write(to: logURL, atomically: true, encoding: .utf8)
            }
        }
        // #endregion
        
        if let image, let storedPath = try? imageStore.saveImage(image, id: receipt.id) {
            receipt.imagePath = storedPath
            
            // Lagre til fotobibliotek hvis innstillingen er aktivert
            // Dette gjøres asynkront og feil håndteres stille (appen skal ikke krasje hvis tilgang nektes)
            if saveToPhoto {
                // #region agent log
                Self.logger.debug("Creating Task to save to photo library")
                let taskLogData: [String: Any] = [
                    "sessionId": "debug-session",
                    "runId": "pre-fix",
                    "hypothesisId": "H0",
                    "location": "ReceiptRepository.swift:275",
                    "message": "Creating Task to save to photo library",
                    "data": [:],
                    "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
                ]
                if let jsonData = try? JSONSerialization.data(withJSONObject: taskLogData), let jsonString = String(data: jsonData, encoding: .utf8) {
                    if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                        defer { try? fileHandle.close() }
                        _ = try? fileHandle.seekToEnd()
                        _ = try? fileHandle.write(contentsOf: (jsonString + "\n").data(using: .utf8)!)
                    } else {
                        try? (jsonString + "\n").write(to: logURL, atomically: true, encoding: .utf8)
                    }
                }
                // #endregion
                
                Task {
                    do {
                        try await imageStore.saveToPhotoLibrary(image)
                    } catch {
                        // Log feil, men ikke krasj appen
                        Self.logger.error("Error saving to photo library: \(error.localizedDescription)")
                        
                        // #region agent log
                        let errorLogData: [String: Any] = [
                            "sessionId": "debug-session",
                            "runId": "pre-fix",
                            "hypothesisId": "H0",
                            "location": "ReceiptRepository.swift:290",
                            "message": "Error saving to photo library",
                            "data": ["error": error.localizedDescription],
                            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
                        ]
                        if let jsonData = try? JSONSerialization.data(withJSONObject: errorLogData), let jsonString = String(data: jsonData, encoding: .utf8) {
                            if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                                defer { try? fileHandle.close() }
                                _ = try? fileHandle.seekToEnd()
                                _ = try? fileHandle.write(contentsOf: (jsonString + "\n").data(using: .utf8)!)
                            } else {
                                try? (jsonString + "\n").write(to: logURL, atomically: true, encoding: .utf8)
                            }
                        }
                        // #endregion
                    }
                }
            }
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
