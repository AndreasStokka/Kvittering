import Foundation
import Vision
import UIKit
import os.log

struct OCRResult {
    var storeName: String?
    var purchaseDate: Date?
    var totalAmount: Decimal?
    var lineItems: [LineItem]
    var rawText: String = "" // For debugging
}

struct OCRService {
    private let storeNameMatcher = StoreNameMatcher()
    private static let logger = Logger(subsystem: "com.example.Kvittering", category: "OCRService")
    
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
    
    func recognizeText(from image: UIImage, recognitionLevel: VNRequestTextRecognitionLevel = .accurate) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = recognitionLevel
        
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
        
        // Log recognition level, revision, and language
        let levelString = recognitionLevel == .fast ? "fast" : "accurate"
        let revision = request.revision
        let languages = request.recognitionLanguages.joined(separator: ", ")
        Self.logger.debug("OCR Recognition: level=\(levelString), revision=\(revision), languages=[\(languages)]")
        
        // Log language from first observation if available
        if let firstObservation = observations.first,
           let topCandidate = firstObservation.topCandidates(1).first {
            // Log detected language if available (may not be directly accessible, but we log what we can)
            Self.logger.debug("OCR First observation: confidence=\(topCandidate.confidence)")
        }
        
        // Alltid log OCR-tekst for debugging
        Self.logger.debug("OCR Raw text:\n\(text)")
        
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
        let dateString = date.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .none) } ?? "nil"
        let totalString = total.map { String(describing: $0) } ?? "nil"
        
        var logMessage = "OCR Parsed Result - Store: \(store ?? "nil"), Date: \(dateString), Total: \(totalString), LineItems: \(items.count)"
        if !items.isEmpty {
            let itemsDetails = items.enumerated().map { "[\($0.offset)] \($0.element.descriptionText)" }.joined(separator: "\n")
            logMessage += "\nLineItems details:\n\(itemsDetails)"
        }
        Self.logger.debug("\(logMessage)")
        
        return OCRResult(storeName: store, purchaseDate: date, totalAmount: total, lineItems: items, rawText: text)
    }

    private func detectStoreName(in lines: [String]) -> String? {
        // Først: Prøv å matche mot kjente butikknavn
        // Sjekk også deler av linjer (første ord eller første del) for bedre matching
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Prøv hele linjen først
            if let matched = storeNameMatcher.matchAndCorrect(trimmed) {
                return matched
            }
            
            // Prøv også første ord/del av linjen (f.eks. "SPORT 1 FORDE AS" → "SPORT 1")
            let words = trimmed.components(separatedBy: .whitespaces)
            if words.count > 0 {
                // Prøv første ord
                if let matched = storeNameMatcher.matchAndCorrect(words[0]) {
                    return matched
                }
                // Prøv første to ord (f.eks. "SPORT 1")
                if words.count >= 2 {
                    let firstTwoWords = "\(words[0]) \(words[1])"
                    if let matched = storeNameMatcher.matchAndCorrect(firstTwoWords) {
                        return matched
                    }
                }
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
        var itemLines: [String] = []
        
        // Log date and total indices for debugging
        if let dateIdx = dateIndex {
            Self.logger.debug("Date found at line \(dateIdx): '\(lines[dateIdx])'")
        } else {
            Self.logger.debug("Date index not found")
        }
        if let totalIdx = totalIndex {
            Self.logger.debug("Total found at line \(totalIdx): '\(lines[totalIdx])'")
        } else {
            Self.logger.debug("Total index not found")
        }
        
        if let dateIdx = dateIndex, let totalIdx = totalIndex, dateIdx < totalIdx {
            // Normal case: Extract lines between date and total (exclusive of date and total lines)
            itemLines = Array(lines[(dateIdx + 1)..<totalIdx])
            Self.logger.debug("Line items region: lines \(dateIdx + 1) to \(totalIdx - 1) (between date and total)")
        } else if let totalIdx = totalIndex, totalIdx > 0 {
            // Fallback 1: dateIndex missing, use all lines before total
            // Find first amount line after header (skip first few lines that are likely header)
            let headerEndIndex = min(5, totalIdx)
            var startIndex = headerEndIndex
            
            // Look for first line with an amount pattern (likely first line item)
            for i in headerEndIndex..<totalIdx {
                let line = lines[i]
                // Check if line contains an amount pattern
                if let amountRegex = try? NSRegularExpression(pattern: #"[-]?[0-9]{1,3}(?:[\s.][0-9]{3})*[.,][0-9]{2}"#) {
                    let nsLine = line as NSString
                    if amountRegex.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) != nil {
                        startIndex = i
                        break
                    }
                }
            }
            
            itemLines = Array(lines[startIndex..<totalIdx])
            Self.logger.debug("Line items region (dateIndex missing): lines \(startIndex) to \(totalIdx - 1) (first amount line after header to total)")
        } else if let dateIdx = dateIndex, dateIdx + 1 < lines.count {
            // Fallback 2: totalIndex missing, use all lines after date
            // Find last amount line (likely last line item before summary)
            var endIndex = lines.count
            
            // Look backwards from end for last amount line
            for i in stride(from: lines.count - 1, through: dateIdx + 1, by: -1) {
                let line = lines[i]
                // Check if line contains an amount pattern
                if let amountRegex = try? NSRegularExpression(pattern: #"[-]?[0-9]{1,3}(?:[\s.][0-9]{3})*[.,][0-9]{2}"#) {
                    let nsLine = line as NSString
                    if amountRegex.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) != nil {
                        endIndex = i + 1
                        break
                    }
                }
            }
            
            itemLines = Array(lines[(dateIdx + 1)..<endIndex])
            Self.logger.debug("Line items region (totalIndex missing): lines \(dateIdx + 1) to \(endIndex - 1) (after date to last amount line)")
        } else {
            // Fallback 3: Both missing, try to find region by looking for amount patterns
            // Skip header (first few lines) and footer (last few lines)
            let headerSkip = min(3, lines.count)
            let footerSkip = min(3, lines.count)
            let startIndex = headerSkip
            let endIndex = max(headerSkip, lines.count - footerSkip)
            
            itemLines = Array(lines[startIndex..<endIndex])
            Self.logger.debug("Line items region (both indices missing): lines \(startIndex) to \(endIndex - 1) (estimated region)")
        }
        
        // Log included lines for debugging
        if !itemLines.isEmpty {
            Self.logger.debug("Included lines for parsing (\(itemLines.count) lines):\n\(itemLines.joined(separator: "\n"))")
        } else {
            Self.logger.debug("No lines included for parsing")
        }
        
        return parseLineItemsFromLines(itemLines, totalAmount: totalAmount)
    }
    
    private func parseLineItemsFromLines(_ lines: [String], totalAmount: Decimal?) -> [LineItem] {
        var lineItems: [LineItem] = []
        
        // Normaliser linjer først for å korrigere norske bokstaver
        let normalizedLines = lines.map { TextNormalizer.correctNorwegianCharacters($0) }
        
        // Pattern to match: product name followed by price
        // Bruk Unicode-aware regex (\p{L} for bokstaver) og støtt tusenskilletegn og kr/NOK
        // Examples: "Melk 1L 25,90", "Brød 2x 19,50", "Vare 1 250.00", "Vare 2 379.15 kr", "Rabatt -50,00"
        let lineItemPatterns = [
            // Product + price (med eller uten kr/NOK, med eller uten tusenskilletegn, støtt negative beløp)
            "^(.+?)\\s+([-]?[0-9]{1,3}(?:[\\s.][0-9]{3})*[.,][0-9]{2})(?:\\s*(?:kr|NOK))?$",
            // Quantity + product + price
            "^([0-9]+[xX]?)\\s*(.+?)\\s+([-]?[0-9]{1,3}(?:[\\s.][0-9]{3})*[.,][0-9]{2})(?:\\s*(?:kr|NOK))?$"
        ]
        
        // Pattern to match just a price (for multi-line items), med eller uten kr/NOK, støtt negative beløp
        // Støtt også beløp med mellomrom mellom tusenvis: "2 379.15" eller "2 379,15"
        let priceOnlyPattern = "^([-]?\\s*[0-9]{1,3}(?:[\\s.][0-9]{3})*[.,][0-9]{2})(?:\\s*(?:kr|NOK))?$"
        
        var index = 0
        while index < normalizedLines.count {
            let line = normalizedLines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines, headers, and summary lines
            // Merk: Vi hopper IKKE over rabattlinjer lenger - de skal parses som negative beløp
            guard !trimmed.isEmpty,
                  trimmed.count > 3 else {
                index += 1
                continue
            }
            
            // For rabattlinjer, tillat negative beløp
            let isDiscountLine = trimmed.lowercased().contains("rabatt")
            let isSummaryLine = trimmed.lowercased().contains("totalt") || 
                                trimmed.lowercased().contains("sum") ||
                                trimmed.lowercased().contains("mva")
            
            if isSummaryLine {
                index += 1
                continue
            }
            
            // Skip lines that are mostly numbers or special characters (unntatt rabattlinjer)
            if !isDiscountLine {
                // Bruk Unicode-aware check for bokstaver (\p{L})
                let nsTrimmed = trimmed as NSString
                if let letterRegex = try? NSRegularExpression(pattern: #"\p{L}"#) {
                    let letterMatches = letterRegex.matches(in: trimmed, range: NSRange(location: 0, length: nsTrimmed.length))
                    guard letterMatches.count >= 2 else {
                        index += 1
                        continue
                    }
                } else {
                    // Fallback til vanlig check
                    let letterCount = trimmed.filter { $0.isLetter }.count
                    guard letterCount >= 2 else {
                        index += 1
                        continue
                    }
                }
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
                    
                    // Parse price (støtt negative beløp for rabatter)
                    let normalizedPrice = priceString
                        .replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: ",", with: ".")
                    if let price = Decimal(string: normalizedPrice), !price.isNaN && !price.isInfinite {
                        unitPrice = abs(price) // Lagre absoluttverdi for unitPrice
                        // Valider quantity før beregning
                        if !quantity.isNaN && !quantity.isInfinite {
                            lineTotal = quantity * price // Behold fortegn for rabatter
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
                        
                        // Parse price (støtt negative beløp for rabatter)
                        let normalizedPrice = priceString
                            .replacingOccurrences(of: " ", with: "")
                            .replacingOccurrences(of: ",", with: ".")
                        if let price = Decimal(string: normalizedPrice), !price.isNaN && !price.isInfinite {
                            unitPrice = abs(price) // Lagre absoluttverdi for unitPrice
                            lineTotal = price // Behold fortegn for lineTotal (kan være negativ for rabatter)
                        }
                    }
                }
            }
            
            // Handle multi-line items (product name and price on separate lines)
            // Two cases:
            // 1. Product name on current line, price on next line: "Essentials 3L Shell" → "2 379.15"
            // 2. Price on previous line, product name on current line: "2 379.15" → "Essentials 3L Shell"
            if descriptionText == nil {
                let nsTrimmed = trimmed as NSString
                var hasLetters = false
                if let letterRegex = try? NSRegularExpression(pattern: #"\p{L}"#) {
                    let letterMatches = letterRegex.matches(in: trimmed, range: NSRange(location: 0, length: nsTrimmed.length))
                    hasLetters = letterMatches.count >= 3
                } else {
                    hasLetters = trimmed.filter { $0.isLetter }.count >= 3
                }
                
                let hasPricePattern = (try? NSRegularExpression(pattern: lineItemPatterns[0]))?.firstMatch(in: trimmed, range: NSRange(location: 0, length: nsTrimmed.length)) != nil
                
                // Case 1: Check if next line is just a price (product name on current line, price on next)
                if hasLetters && !hasPricePattern && index + 1 < normalizedLines.count {
                    let nextLine = normalizedLines[index + 1].trimmingCharacters(in: .whitespaces)
                    
                    // Try priceOnlyPattern first (strict match)
                    if let priceRegex = try? NSRegularExpression(pattern: priceOnlyPattern),
                       let priceMatch = priceRegex.firstMatch(in: nextLine, range: NSRange(location: 0, length: nextLine.count)),
                       priceMatch.numberOfRanges >= 2 {
                        
                        let priceString = (nextLine as NSString).substring(with: priceMatch.range(at: 1))
                        let normalizedPrice = priceString
                            .replacingOccurrences(of: " ", with: "")
                            .replacingOccurrences(of: ",", with: ".")
                        
                        if let price = Decimal(string: normalizedPrice), !price.isNaN && !price.isInfinite {
                            descriptionText = trimmed
                            unitPrice = abs(price) // Lagre absoluttverdi for unitPrice
                            lineTotal = price // Behold fortegn for lineTotal (kan være negativ for rabatter)
                            // Skip next line since we've used it
                            index += 1
                        }
                    } else {
                        // Fallback: Check if next line looks like a price (contains amount pattern even if not strict match)
                        // This handles cases like "2 379.15" where spacing might not match exactly
                        let amountPattern = #"[-]?[0-9]{1,3}(?:[\s.][0-9]{3})*[.,][0-9]{2}"#
                        if let amountRegex = try? NSRegularExpression(pattern: amountPattern),
                           let amountMatch = amountRegex.firstMatch(in: nextLine, range: NSRange(location: 0, length: nextLine.count)) {
                            
                            // Verify next line is mostly just a price (few letters, mostly numbers/spaces)
                            let nextHasLetters: Int
                            if let letterRegex = try? NSRegularExpression(pattern: #"\p{L}"#) {
                                let nsNext = nextLine as NSString
                                let letterMatches = letterRegex.matches(in: nextLine, range: NSRange(location: 0, length: nsNext.length))
                                nextHasLetters = letterMatches.count
                            } else {
                                nextHasLetters = nextLine.filter { $0.isLetter }.count
                            }
                            
                            // If next line has few letters (mostly just price), treat it as a price line
                            if nextHasLetters < 3 {
                                let priceString = (nextLine as NSString).substring(with: amountMatch.range)
                                let normalizedPrice = priceString
                                    .replacingOccurrences(of: " ", with: "")
                                    .replacingOccurrences(of: ",", with: ".")
                                
                                if let price = Decimal(string: normalizedPrice), !price.isNaN && !price.isInfinite {
                                    descriptionText = trimmed
                                    unitPrice = abs(price) // Lagre absoluttverdi for unitPrice
                                    lineTotal = price // Behold fortegn for lineTotal (kan være negativ for rabatter)
                                    // Skip next line since we've used it
                                    index += 1
                                }
                            }
                        }
                    }
                }
                
                // Case 2: Check if previous line was just a price (price on previous line, product name on current)
                if descriptionText == nil && hasLetters && !hasPricePattern && index > 0 {
                    let prevLine = normalizedLines[index - 1].trimmingCharacters(in: .whitespaces)
                    
                    // Check if previous line is just a price (and not already used by a previous item)
                    if let priceRegex = try? NSRegularExpression(pattern: priceOnlyPattern),
                       let priceMatch = priceRegex.firstMatch(in: prevLine, range: NSRange(location: 0, length: prevLine.count)),
                       priceMatch.numberOfRanges >= 2 {
                        
                        // Verify previous line doesn't look like a product name (mostly numbers/price only)
                        let prevHasLetters: Int
                        if let letterRegex = try? NSRegularExpression(pattern: #"\p{L}"#) {
                            let nsPrev = prevLine as NSString
                            let letterMatches = letterRegex.matches(in: prevLine, range: NSRange(location: 0, length: nsPrev.length))
                            prevHasLetters = letterMatches.count
                        } else {
                            prevHasLetters = prevLine.filter { $0.isLetter }.count
                        }
                        
                        // If previous line is mostly just a price (few letters), use it
                        if prevHasLetters < 3 {
                            let priceString = (prevLine as NSString).substring(with: priceMatch.range(at: 1))
                            let normalizedPrice = priceString
                                .replacingOccurrences(of: " ", with: "")
                                .replacingOccurrences(of: ",", with: ".")
                            
                            if let price = Decimal(string: normalizedPrice), !price.isNaN && !price.isInfinite {
                                descriptionText = trimmed
                                unitPrice = abs(price) // Lagre absoluttverdi for unitPrice
                                lineTotal = price // Behold fortegn for lineTotal (kan være negativ for rabatter)
                            }
                        }
                    }
                }
            }
            
            // Validate and add line item
            // Tillat negative beløp for rabatter (ikke lenger total > 0 requirement)
            if let description = descriptionText,
               !description.isEmpty,
               let price = unitPrice,
               let total = lineTotal,
               price > 0, // unitPrice skal alltid være positiv (vi bruker abs)
               !price.isNaN,
               !price.isInfinite,
               !total.isNaN,
               !total.isInfinite,
               !quantity.isNaN,
               !quantity.isInfinite {
                
                // Validate against total amount if available (kun for positive beløp)
                if let receiptTotal = totalAmount, total > 0, total > receiptTotal {
                    index += 1
                    continue // Skip if line total exceeds receipt total
                }
                
                // Skip if price seems unrealistic (too high for a single item, kun for positive)
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
