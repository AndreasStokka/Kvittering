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
        
        print("OCR Raw text:\n\(text)")
        return text
    }

    func parse(from text: String) -> OCRResult {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        print("OCR Lines: \(lines)")
        let store = detectStoreName(in: lines)
        let date = detectDate(in: lines)
        let total = detectTotal(in: lines)
        let items: [LineItem] = []
        print("OCR Result - Store: \(store ?? "nil"), Date: \(String(describing: date)), Total: \(String(describing: total))")
        return OCRResult(storeName: store, purchaseDate: date, totalAmount: total, lineItems: items, rawText: text)
    }

    private func detectStoreName(in lines: [String]) -> String? {
        // Kjente butikknavn å se etter
        let knownStores = ["sport 1", "rema", "kiwi", "coop", "extra", "meny", "bunnpris", "spar", "joker", "europris", "jula", "byggmax", "obs", "elkjøp", "power", "xxl"]
        
        // Først: Sjekk om noen kjente butikknavn finnes
        for line in lines {
            let lineLower = line.lowercased()
            for store in knownStores {
                if lineLower.contains(store) {
                    // Returner hele linjen eller del av den
                    return line.trimmingCharacters(in: .whitespaces)
                }
            }
        }
        
        // Fallback: Finn første gyldige linje
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
            
            return trimmed
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
                        print("  -> Found date (yyyy-MM-dd): \(dateString)")
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
                        print("  -> Found date (dd.MM.yyyy): \(normalized)")
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
                        print("  -> Found date (fallback): \(dateString)")
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
        
        var candidates: [(amount: Decimal, priority: Int, line: String)] = []
        var afterTotalKeyword = false
        
        for (_, line) in lines.enumerated() {
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
                        // Filtrer ut urealistiske beløp
                        guard value >= 10 && value < 100000 else { continue }
                        
                        // Prioritering:
                        // 20: Beløp på linje rett etter "Totalt" eller "Bank:"
                        // 15: Beløp på samme linje som nøkkelord
                        // 10: Beløp som gjentar seg (sannsynligvis total)
                        // 1: Vanlig beløp
                        var priority = 1
                        
                        if afterTotalKeyword {
                            priority = 20
                        } else if hasKeyword {
                            priority = 15
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
                        
                        candidates.append((value, priority, line))
                        print("  -> Found amount: \(raw) -> \(value) (priority: \(priority))")
                    }
                }
            }
            
            // Sett flagg for neste iterasjon
            afterTotalKeyword = hasKeyword
        }
        
        print("OCR Amount candidates count: \(candidates.count)")
        
        // Sorter etter prioritet først, deretter beløp
        return candidates.sorted { 
            if $0.priority != $1.priority {
                return $0.priority > $1.priority
            }
            return $0.amount > $1.amount
        }.first?.amount
    }
}
