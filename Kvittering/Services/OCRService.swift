import Foundation
import Vision
import UIKit

struct OCRResult {
    var storeName: String?
    var purchaseDate: Date?
    var totalAmount: Decimal?
    var lineItems: [LineItem]
}

struct OCRService {
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw NSError(domain: "OCR", code: 0) }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["nb-NO", "no", "en-US"]
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        let observations = request.results ?? []
        return observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }

    func parse(from text: String) -> OCRResult {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let store = detectStoreName(in: lines)
        let date = detectDate(in: lines)
        let total = detectTotal(in: lines)
        let items: [LineItem] = []
        return OCRResult(storeName: store, purchaseDate: date, totalAmount: total, lineItems: items)
    }

    private func detectStoreName(in lines: [String]) -> String? {
        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if detectDate(in: [trimmed]) == nil, detectTotal(in: [trimmed]) == nil {
                return trimmed.capitalized
            }
        }
        return nil
    }

    private func detectDate(in lines: [String]) -> Date? {
        let patterns = ["\\b(\\d{2})[\\./-](\\d{2})[\\./-](\\d{4})\\b"]
        for line in lines {
            for pattern in patterns {
                if let match = line.range(of: pattern, options: .regularExpression) {
                    let dateString = String(line[match])
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "nb_NO")
                    formatter.dateFormat = "dd.MM.yyyy"
                    if let date = formatter.date(from: dateString.replacingOccurrences(of: "-", with: ".").replacingOccurrences(of: "/", with: ".")) {
                        return date
                    }
                }
            }
        }
        return nil
    }

    private func detectTotal(in lines: [String]) -> Decimal? {
        let amountPattern = "[0-9]{1,3}(?:[\\s.]?[0-9]{3})*(?:,[0-9]{2})?"
        var candidates: [Decimal] = []
        for line in lines {
            let nsLine = line as NSString
            let regex = try? NSRegularExpression(pattern: amountPattern)
            let matches = regex?.matches(in: line, range: NSRange(location: 0, length: nsLine.length)) ?? []
            for match in matches {
                let raw = nsLine.substring(with: match.range)
                let normalized = raw.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ".", with: "")
                let decimalString = normalized.replacingOccurrences(of: ",", with: ".")
                if let value = Decimal(string: decimalString) {
                    candidates.append(value)
                }
            }
        }
        return candidates.max()
    }
}
