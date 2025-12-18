import Foundation
import Vision
import UIKit

struct OCRResult {
    var storeName: String?
    var purchaseDate: Date?
    var totalAmount: Decimal?
    var lineItems: [LineItem]
    var rawText: String = "" // For debugging
}

struct OCRService {
    private let storeNameMatcher = StoreNameMatcher()
    
    /// Feiltyper for OCR-prosessering
    enum OCRError: LocalizedError {
        case invalidImage
        case recognitionFailed(underlying: Error)
        case noTextFound
        
        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Kunne ikke behandle bildet. Prøv å ta et nytt bilde med bedre belysning."
            case .recognitionFailed(let error):
                return "Tekstgjenkjenning feilet: \(error.localizedDescription)"
            case .noTextFound:
                return "Fant ingen tekst i bildet. Sørg for at kvitteringen er tydelig synlig."
            }
        }
    }
    
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        
        // Prioriter norsk tekst først, men behold engelsk som fallback for blandede kvitteringer.
        // Vision støtter norsk on-device og er gratis, så dette gir bedre presisjon uten
        // å sende data til tredjepart.
        request.recognitionLanguages = ["nb-NO", "nn-NO", "no", "en-US", "en-GB"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            throw OCRError.recognitionFailed(underlying: error)
        }
        
        let observations = request.results ?? []
        let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
        
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw OCRError.noTextFound
        }
        
        // Alltid log OCR-tekst for debugging
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔍 OCR Raw text:")
        print(text)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        return text
    }

    func parse(from text: String) -> OCRResult {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let store = detectStoreName(in: lines)
        let date = detectDate(in: lines)
        let total = detectTotal(in: lines)
        
        // Find indices for date and total to identify line items region
        var dateIndex: Int?
        var totalIndex: Int?
        
        // Find date index by checking each line
        if let detectedDate = date {
            for (index, line) in lines.enumerated() {
                if let lineDate = detectDate(in: [line]) {
                    // Compare dates by calendar components to avoid time component issues
                    let calendar = Calendar.current
                    if calendar.isDate(detectedDate, inSameDayAs: lineDate) {
                        dateIndex = index
                        break
                    }
                }
            }
        }
        
        // Find total index by checking each line
        if let detectedTotal = total {
            for (index, line) in lines.enumerated() {
                if let lineTotal = detectTotal(in: [line]) {
                    // Compare Decimal values directly
                    if lineTotal == detectedTotal {
                        totalIndex = index
                        break
                    }
                }
            }
        }
        
        let items = detectLineItems(in: lines, dateIndex: dateIndex, totalIndex: totalIndex, totalAmount: total)
        
        // Alltid log parsed resultat for debugging
        let dateString = date != nil ? DateFormatter.localizedString(from: date!, dateStyle: .short, timeStyle: .none) : "nil"
        let totalString = total != nil ? String(describing: total!) : "nil"
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 OCR Parsed Result:")
        print("  Store: \(store ?? "nil")")
        print("  Date: \(dateString)")
        print("  Total: \(totalString)")
        print("  LineItems: \(items.count)")
        if !items.isEmpty {
            print("  LineItems details:")
            for (index, item) in items.enumerated() {
                print("    [\(index)] \(item.descriptionText) - \(item.quantity)x @ \(item.unitPrice) = \(item.lineTotal)")
            }
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        return OCRResult(storeName: store, purchaseDate: date, totalAmount: total, lineItems: items, rawText: text)
    }

    private func detectStoreName(in lines: [String]) -> String? {
        // Først: Prøv å matche mot kjente butikknavn
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Prøv å matche og korrigere butikknavn
            if let matched = storeNameMatcher.matchAndCorrect(trimmed) {
                return matched
            }
        }
        
        // Fallback: Finn første gyldige linje og normaliser den
        for line in lines.prefix(15) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Hopp over veldig korte linjer
            guard trimmed.count > 3 else { continue }
            
            // Hopp over linjer som bare er tall eller spesialtegn
            if trimmed.allSatisfy({ $0.isNumber || $0.isWhitespace || $0 == "." || $0 == "-" || $0 == "/" || $0 == ":" }) {
                continue
            }
            
            // Hopp over maskerte kortnumre (XXXX XXXX XXXX XXX2)
            if trimmed.contains("XXXX") || trimmed.contains("xxxx") || trimmed.contains("****") {
                continue
            }
            
            // Hopp over linjer med X og tall (maskerte numre)
            let xCount = trimmed.filter { $0 == "X" || $0 == "x" || $0 == "*" }.count
            if xCount > 3 {
                continue
            }
            
            let digitCount = trimmed.filter { $0.isNumber }.count
            let colonCount = trimmed.filter { $0 == ":" }.count
            
            // Hopp over hvis det er for mange tall eller koloner
            if digitCount > trimmed.count / 2 || colonCount > 0 {
                continue
            }
            
            // Hopp over hvis det er en dato eller beløp
            if detectDate(in: [trimmed]) != nil {
                continue
            }
            
            // Sjekk om det er minimum 3 bokstaver
            let letterCount = trimmed.filter { $0.isLetter }.count
            guard letterCount >= 3 else { continue }
            
            // Normaliser og returner
            return TextNormalizer.normalizeStoreName(trimmed)
        }
        return nil
    }

    private func detectDate(in lines: [String]) -> Date? {
        // Norsk format: dd.MM.yyyy eller yyyy-MM-dd
        let patterns = [
            "\\b(\\d{4})-(\\d{2})-(\\d{2})\\b",  // 2025-10-16
            "\\b(\\d{2})[\\./-](\\d{2})[\\./-](\\d{4})\\b"  // 16.10.2025
        ]
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        for line in lines {
            // Først prøv yyyy-MM-dd format
            if let match = line.range(of: patterns[0], options: .regularExpression) {
                let dateString = String(line[match])
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: dateString) {
                    // Valider at datoen er rimelig (mellom 2020 og 2030)
                    let year = Calendar.current.component(.year, from: date)
                    if year >= 2020 && year <= 2030 {
                        return date
                    }
                }
            }
            
            // Så prøv dd.MM.yyyy format
            if let match = line.range(of: patterns[1], options: .regularExpression) {
                let dateString = String(line[match])
                let normalized = dateString.replacingOccurrences(of: "-", with: ".").replacingOccurrences(of: "/", with: ".")
                formatter.dateFormat = "dd.MM.yyyy"
                if let date = formatter.date(from: normalized) {
                    let year = Calendar.current.component(.year, from: date)
                    if year >= 2020 && year <= 2030 {
                        return date
                    }
                }
            }
        }
        
        // Fallback: Prøv å finne dato i "NOK 2379.15" linjer som ofte har dato
        for line in lines {
            // Søk etter dato som del av en lengre streng
            let nsLine = line as NSString
            if let regex = try? NSRegularExpression(pattern: "(\\d{4})-(\\d{1,2})-(\\d{1,2})"),
               let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) {
                let dateString = nsLine.substring(with: match.range)
                formatter.dateFormat = "yyyy-M-d"
                if let date = formatter.date(from: dateString) {
                    let year = Calendar.current.component(.year, from: date)
                    if year >= 2020 && year <= 2030 {
                        return date
                    }
                }
            }
        }
        
        return nil
    }

    private func detectTotal(in lines: [String]) -> Decimal? {
        // Støtt både norsk (2 379,15) og engelsk (2 379.15) format
        // Pattern matcher: tall med valgfritt tusenskilletegn, så enten komma eller punktum, så to desimaler
        let amountPatterns = [
            "[0-9]{1,3}(?:[\\s][0-9]{3})*[.,][0-9]{2}",  // 2 379.15 eller 2 379,15
            "[0-9]{3,}[.,][0-9]{2}"                        // 2379.15 eller 2379,15
        ]
        let totalKeywords = ["totalt", "total", "sum", "å betale", "bank", "beløp", "artikkel", "betalt", "varekjøp", "nok"]
        let skipKeywords = ["rabatt", "mva", "grunnlag", "medlems"]
        
        var candidates: [(amount: Decimal, priority: Int, lineIndex: Int, line: String)] = []
        var afterTotalKeyword = false
        
        for (lineIndex, line) in lines.enumerated() {
            let lineLower = line.lowercased()
            
            // Sjekk om denne linjen inneholder total-nøkkelord
            let hasKeyword = totalKeywords.contains(where: { lineLower.contains($0) })
            let shouldSkip = skipKeywords.contains(where: { lineLower.contains($0) })
            
            if shouldSkip { 
                afterTotalKeyword = false
                continue 
            }
            
            let nsLine = line as NSString
            
            for pattern in amountPatterns {
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
                
                for match in matches {
                    let raw = nsLine.substring(with: match.range)
                    // Normaliser: fjern mellomrom, erstatt komma med punktum
                    let normalized = raw
                        .replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: ",", with: ".")
                    
                    if let value = Decimal(string: normalized) {
                        // Filtrer ut NaN, uendelig og urealistiske beløp
                        guard !value.isNaN && !value.isInfinite else { continue }
                        guard value >= 10 && value < 100000 else { continue }
                        
                        // Prioritering:
                        // 30: Beløp på linje rett etter "Totalt" eller "Bank:" (høyest prioritet)
                        // 20: Beløp på samme linje som nøkkelord
                        // 15: Beløp nær slutten av kvitteringen (siste 20% av linjer)
                        // 10: Beløp som gjentar seg (sannsynligvis total)
                        // 5: Beløp som er større enn gjennomsnittet av alle beløp
                        // 1: Vanlig beløp
                        var priority = 1
                        
                        if afterTotalKeyword {
                            priority = 30
                        } else if hasKeyword {
                            priority = 20
                        }
                        
                        // Prioriter beløp nær slutten av kvitteringen
                        let totalLines = lines.count
                        let positionRatio = Double(lineIndex) / Double(max(totalLines, 1))
                        if positionRatio > 0.8 {
                            priority = max(priority, 15)
                        }
                        
                        // Sjekk om dette beløpet gjentar seg (normaliser for sammenligning)
                        let normalizedForCompare = normalized
                        let repeatCount = lines.filter { line in
                            let lineNorm = line.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ",", with: ".")
                            return lineNorm.contains(normalizedForCompare)
                        }.count
                        if repeatCount >= 2 {
                            priority = max(priority, 10)
                        }
                        
                        // Prioriter større beløp (total er vanligvis størst)
                        let allAmounts = candidates.map { $0.amount }
                        if let maxAmount = allAmounts.max(), value >= maxAmount {
                            priority = max(priority, 5)
                        }
                        
                        candidates.append((value, priority, lineIndex, line))
                    }
                }
            }
            
            // Sett flagg for neste iterasjon
            afterTotalKeyword = hasKeyword
        }
        
        // Sorter etter prioritet først, deretter beløp (størst først)
        let sorted = candidates.sorted { 
            if $0.priority != $1.priority {
                return $0.priority > $1.priority
            }
            return $0.amount > $1.amount
        }
        
        #if DEBUG
        if !sorted.isEmpty {
            NSLog("💰 OCR Beløp-kandidater (topp 3):")
            for (index, candidate) in sorted.prefix(3).enumerated() {
                NSLog("  %d. %@ (prioritet: %d, linje: %d)", 
                      index + 1, 
                      String(describing: candidate.amount), 
                      candidate.priority, 
                      candidate.lineIndex)
            }
        }
        #endif
        
        return sorted.first?.amount
    }
    
    private func detectLineItems(in lines: [String], dateIndex: Int?, totalIndex: Int?, totalAmount: Decimal?) -> [LineItem] {
        guard let dateIdx = dateIndex, let totalIdx = totalIndex, dateIdx < totalIdx else {
            // If we can't find date/total indices, try to parse all lines before the total
            if let totalIdx = totalIndex, totalIdx > 0 {
                return parseLineItemsFromLines(Array(lines[0..<totalIdx]), totalAmount: totalAmount)
            }
            return []
        }
        
        // Extract lines between date and total (exclusive of date and total lines)
        let itemLines = Array(lines[(dateIdx + 1)..<totalIdx])
        return parseLineItemsFromLines(itemLines, totalAmount: totalAmount)
    }
    
    private func parseLineItemsFromLines(_ lines: [String], totalAmount: Decimal?) -> [LineItem] {
        var lineItems: [LineItem] = []
        
        // Pattern to match: product name followed by price
        // Examples: "Melk 1L 25,90", "Brød 2x 19,50", "Vare 1 250.00"
        let lineItemPatterns = [
            "^(.+?)\\s+([0-9]{1,3}(?:[\\s.][0-9]{3})*[.,][0-9]{2})$",  // Product + price
            "^([0-9]+[xX]?)\\s*(.+?)\\s+([0-9]{1,3}(?:[\\s.][0-9]{3})*[.,][0-9]{2})$"  // Quantity + product + price
        ]
        
        // Pattern to match just a price (for multi-line items)
        let priceOnlyPattern = "^([0-9]{1,3}(?:[\\s.][0-9]{3})*[.,][0-9]{2})$"
        
        var index = 0
        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines, headers, and summary lines
            guard !trimmed.isEmpty,
                  trimmed.count > 3,
                  !trimmed.lowercased().contains("totalt"),
                  !trimmed.lowercased().contains("sum"),
                  !trimmed.lowercased().contains("mva"),
                  !trimmed.lowercased().contains("rabatt") else {
                index += 1
                continue
            }
            
            // Skip lines that are mostly numbers or special characters
            let letterCount = trimmed.filter { $0.isLetter }.count
            guard letterCount >= 2 else {
                index += 1
                continue
            }
            
            var descriptionText: String?
            var quantity: Decimal = 1
            var unitPrice: Decimal?
            var lineTotal: Decimal?
            
            // Try pattern with quantity first (e.g., "2x Melk 25,90")
            if let regex = try? NSRegularExpression(pattern: lineItemPatterns[1]) {
                let nsLine = trimmed as NSString
                if let match = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: nsLine.length)),
                   match.numberOfRanges >= 4 {
                    let qtyString = nsLine.substring(with: match.range(at: 1))
                    let productName = nsLine.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
                    let priceString = nsLine.substring(with: match.range(at: 3))
                    
                    // Parse quantity (remove 'x' if present)
                    let qtyNormalized = qtyString.replacingOccurrences(of: "x", with: "", options: .caseInsensitive)
                    if let qty = Decimal(string: qtyNormalized), !qty.isNaN && !qty.isInfinite && qty > 0 {
                        quantity = qty
                    }
                    
                    descriptionText = productName
                    
                    // Parse price
                    let normalizedPrice = priceString
                        .replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: ",", with: ".")
                    if let price = Decimal(string: normalizedPrice), !price.isNaN && !price.isInfinite {
                        unitPrice = price
                        // Valider quantity før beregning
                        if !quantity.isNaN && !quantity.isInfinite {
                            lineTotal = quantity * price
                            // Valider lineTotal etter beregning
                            if lineTotal?.isNaN == true || lineTotal?.isInfinite == true {
                                lineTotal = nil
                            }
                        }
                    }
                }
            }
            
            // If quantity pattern didn't match, try simple product + price pattern
            if descriptionText == nil {
                if let regex = try? NSRegularExpression(pattern: lineItemPatterns[0]) {
                    let nsLine = trimmed as NSString
                    if let match = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: nsLine.length)),
                       match.numberOfRanges >= 3 {
                        let productName = nsLine.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                        let priceString = nsLine.substring(with: match.range(at: 2))
                        
                        descriptionText = productName
                        
                        // Parse price
                        let normalizedPrice = priceString
                            .replacingOccurrences(of: " ", with: "")
                            .replacingOccurrences(of: ",", with: ".")
                        if let price = Decimal(string: normalizedPrice), !price.isNaN && !price.isInfinite {
                            unitPrice = price
                            lineTotal = price
                        }
                    }
                }
            }
            
            // Handle multi-line items (product name on one line, price on next line)
            // Example: "Essentials 3L Shell" on one line, "2 379.15" on next line
            if descriptionText == nil && index + 1 < lines.count {
                let nextLine = lines[index + 1].trimmingCharacters(in: .whitespaces)
                
                // Check if current line looks like a product name (has letters, no price pattern)
                let hasLetters = trimmed.filter { $0.isLetter }.count >= 3
                let hasPricePattern = (try? NSRegularExpression(pattern: lineItemPatterns[0]))?.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.count)) != nil
                
                // Check if next line is just a price
                if hasLetters && !hasPricePattern,
                   let priceRegex = try? NSRegularExpression(pattern: priceOnlyPattern),
                   let priceMatch = priceRegex.firstMatch(in: nextLine, range: NSRange(location: 0, length: nextLine.count)),
                   priceMatch.numberOfRanges >= 2 {
                    
                    let priceString = (nextLine as NSString).substring(with: priceMatch.range(at: 1))
                    let normalizedPrice = priceString
                        .replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: ",", with: ".")
                    
                    if let price = Decimal(string: normalizedPrice), !price.isNaN && !price.isInfinite {
                        descriptionText = trimmed
                        unitPrice = price
                        lineTotal = price
                        // Skip next line since we've used it
                        index += 1
                    }
                }
            }
            
            // Validate and add line item
            if let description = descriptionText,
               !description.isEmpty,
               let price = unitPrice,
               let total = lineTotal,
               price > 0,
               total > 0,
               !price.isNaN,
               !price.isInfinite,
               !total.isNaN,
               !total.isInfinite,
               !quantity.isNaN,
               !quantity.isInfinite {
                
                // Validate against total amount if available
                if let receiptTotal = totalAmount, total > receiptTotal {
                    index += 1
                    continue // Skip if line total exceeds receipt total
                }
                
                // Skip if price seems unrealistic (too high for a single item)
                if let receiptTotal = totalAmount, price > receiptTotal {
                    index += 1
                    continue
                }
                
                // Normaliser produktnavn før lagring
                let normalizedDescription = TextNormalizer.normalizeProductName(description)
                
                let item = LineItem(
                    descriptionText: normalizedDescription,
                    quantity: quantity,
                    unitPrice: price,
                    lineTotal: total
                )
                lineItems.append(item)
            }
            
            // CRITICAL: Always increment index at the end of the loop
            index += 1
        }
        
        return lineItems
    }
}
