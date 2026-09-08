//
//  DOCXTextExtractor.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 08/09/26.
//

import Foundation
import ZIPFoundation

public enum DOCXError: Error {
    case failedToReadArchive
    case documentXMLNotFound
    case failedToReadDocumentXML
}

public final class DOCXTextExtractor {
    public init() {}

    /// Extracts plain text from a DOCX file by unzipping and parsing word/document.xml.
    /// Returns [1: extractedText] to match the OCR pipeline's page-numbered format.
    public func extractText(from url: URL) async throws -> [Int: String] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    guard let archive = Archive(url: url, accessMode: .read) else {
                        continuation.resume(throwing: DOCXError.failedToReadArchive)
                        return
                    }

                    guard let entry = archive["word/document.xml"] else {
                        continuation.resume(throwing: DOCXError.documentXMLNotFound)
                        return
                    }

                    var data = Data()
                    do {
                        _ = try archive.extract(entry) { chunk in
                            data.append(chunk)
                        }
                    } catch {
                        continuation.resume(throwing: DOCXError.failedToReadDocumentXML)
                        return
                    }

                    let text = Self.stripXMLTags(from: data)
                    continuation.resume(returning: [1: text])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Extracts plain text from DOCX word/document.xml by pulling text from <w:t> elements.
    /// Splits into multiple pages by <w:p> (paragraph) boundaries so the AI parser can process it chunk-by-chunk.
    private static func stripXMLTags(from data: Data) -> String {
        guard let xmlString = String(data: data, encoding: .utf8) else {
            return ""
        }

        // Extract paragraphs with their text nodes
        var paragraphs: [String] = []
        let paragraphPattern = "<w:p[^>]*>(.*?)</w:p>"
        let textPattern = "<w:t[^>]*>([^<]*)</w:t>"

        guard let paraRegex = try? NSRegularExpression(pattern: paragraphPattern, options: [.dotMatchesLineSeparators]),
              let textRegex = try? NSRegularExpression(pattern: textPattern, options: []) else {
            return ""
        }

        let fullRange = NSRange(xmlString.startIndex..., in: xmlString)
        let paraMatches = paraRegex.matches(in: xmlString, options: [], range: fullRange)

        for paraMatch in paraMatches {
            guard let paraRange = Range(paraMatch.range(at: 1), in: xmlString) else { continue }
            let paraContent = String(xmlString[paraRange])

            let textRange = NSRange(paraContent.startIndex..., in: paraContent)
            let textMatches = textRegex.matches(in: paraContent, options: [], range: textRange)
            let texts = textMatches.compactMap { match -> String? in
                guard let range = Range(match.range(at: 1), in: paraContent) else { return nil }
                return String(paraContent[range])
            }

            let paraText = texts.joined(separator: "")
            let trimmed = paraText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                paragraphs.append(trimmed)
            }
        }

        return paragraphs.joined(separator: "\n")
    }
}
