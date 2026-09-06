import Foundation
import UIKit
import Vision

struct OCRResult {
    let fullText: String
    let title: String
    let summary: String
    let entities: ExtractedContent.EntityInfo
}

class OCRService {
    func recognizeText(in image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results, !observations.isEmpty else {
            throw OCRError.noTextFound
        }
        
        let recognizedTexts = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
        
        let fullText = recognizedTexts.joined(separator: "\n")
        
        guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OCRError.noTextFound
        }
        
        let title = extractTitle(from: recognizedTexts)
        let summary = extractSummary(from: fullText)
        let entities = extractEntities(from: fullText)
        
        return OCRResult(
            fullText: fullText,
            title: title,
            summary: summary,
            entities: entities
        )
    }
    
    private func extractTitle(from lines: [String]) -> String {
        let validLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard let firstLine = validLines.first else {
            return "无标题"
        }
        
        let title = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxLength = 50
        
        if title.count > maxLength {
            let index = title.index(title.startIndex, offsetBy: maxLength)
            return String(title[..<index]) + "..."
        }
        
        return title
    }
    
    private func extractSummary(from text: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxLength = 100
        
        if cleaned.count > maxLength {
            let index = cleaned.index(cleaned.startIndex, offsetBy: maxLength)
            return String(cleaned[..<index]) + "..."
        }
        
        return cleaned
    }
    
    private func extractEntities(from text: String) -> ExtractedContent.EntityInfo {
        var entities = ExtractedContent.EntityInfo(
            dates: [],
            amounts: [],
            ids: [],
            contacts: [],
            links: []
        )
        
        entities.dates = extractDates(from: text)
        entities.amounts = extractAmounts(from: text)
        entities.contacts = extractContacts(from: text)
        entities.links = extractLinks(from: text)
        entities.ids = extractIDs(from: text)
        
        return entities
    }
    
    private func extractDates(from text: String) -> [String] {
        let patterns = [
            "\\d{4}[-年]\\d{1,2}[-月]\\d{1,2}[日]?",
            "\\d{1,2}[-/]\\d{1,2}[-/]\\d{2,4}",
            "\\d{4}\\d{2}\\d{2}"
        ]
        
        var dates: [String] = []
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        dates.append(String(text[range]))
                    }
                }
            }
        }
        
        return Array(Set(dates))
    }
    
    private func extractAmounts(from text: String) -> [String] {
        let patterns = [
            "¥\\s?\\d+(?:,\\d{3})*(?:\\.\\d{2})?",
            "\\$\\s?\\d+(?:,\\d{3})*(?:\\.\\d{2})?",
            "\\d+(?:,\\d{3})*(?:\\.\\d{2})?\\s?元"
        ]
        
        var amounts: [String] = []
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        amounts.append(String(text[range]))
                    }
                }
            }
        }
        
        return Array(Set(amounts))
    }
    
    private func extractContacts(from text: String) -> [String] {
        var contacts: [String] = []
        
        let phonePattern = "1[3-9]\\d{9}"
        if let regex = try? NSRegularExpression(pattern: phonePattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    contacts.append(String(text[range]))
                }
            }
        }
        
        let emailPattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        if let regex = try? NSRegularExpression(pattern: emailPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    contacts.append(String(text[range]))
                }
            }
        }
        
        let wechatPattern = "微信[：:号]?\\s*([A-Za-z0-9_-]+)"
        if let regex = try? NSRegularExpression(pattern: wechatPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if match.numberOfRanges > 1,
                   let range = Range(match.range(at: 1), in: text) {
                    contacts.append("微信: \(text[range])")
                }
            }
        }
        
        return Array(Set(contacts))
    }
    
    private func extractLinks(from text: String) -> [String] {
        let pattern = "https?://[^\\s]+"
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        var links: [String] = []
        
        for match in matches {
            if let range = Range(match.range, in: text) {
                links.append(String(text[range]))
            }
        }
        
        return Array(Set(links))
    }
    
    private func extractIDs(from text: String) -> [String] {
        let patterns = [
            "订单号[：:号]?\\s*([A-Z0-9]+)",
            "单号[：:号]?\\s*([A-Z0-9]+)",
            "编号[：:号]?\\s*([A-Z0-9]+)"
        ]
        
        var ids: [String] = []
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if match.numberOfRanges > 1,
                       let range = Range(match.range(at: 1), in: text) {
                        ids.append(String(text[range]))
                    }
                }
            }
        }
        
        return Array(Set(ids))
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case recognitionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return L10n.errorImageLoadFailed
        case .noTextFound:
            return L10n.errorNoTextFound
        case .recognitionFailed:
            return L10n.errorOCRFailed
        }
    }
}
