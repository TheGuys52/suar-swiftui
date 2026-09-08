//
//  VisionOCRService.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 27/08/26.
//

import Foundation
import PDFKit
import UIKit
import UniformTypeIdentifiers
import Vision
import ZIPFoundation

public final class VisionOCRService: VisionOCRServiceProtocol {
    
    public init() {}
    
    public func extractText(
        from url: URL,
        onProgress: ((Double) -> Void)?
    ) async throws -> [Int: String] {
        // Check magic bytes first to avoid PDFDocument succeeding on non-PDF files
        let magicBytes = try Data(contentsOf: url, options: .mappedIfSafe)

        // 1. PATH DOCX — ZIP (PK) based, check before PDF
        if isZIPArchive(data: magicBytes) && isWordDocument(url: url) {
            print("[VisionOCR] Processing DOCX: \(url.lastPathComponent)")
            let extractor = DOCXTextExtractor()
            let result = try await extractor.extractText(from: url)
            print("[VisionOCR] DOCX extracted: \(result.count) pages, page1 chars: \(result[1]?.count ?? 0)")
            onProgress?(1.0)
            return result
        }

        // 2. PATH DOC — legacy binary Word format
        if isLegacyDoc(url: url) {
            print("[VisionOCR] Processing DOC: \(url.lastPathComponent)")
            let attributedString = try NSAttributedString(
                url: url,
                options: [:],
                documentAttributes: nil
            )
            let text = attributedString.string
            print("[VisionOCR] DOC extracted: \(text.count) chars")
            onProgress?(1.0)
            return [1: text]
        }

        // 3. PATH PDF (Digital & Scanned PDF)
        if let pdfDocument = PDFDocument(url: url),
           pdfDocument.pageCount > 0 {
            var rawPagesText: [Int: String] = [:]

            for pageIndex in 0..<pdfDocument.pageCount {
                let pageNum = pageIndex + 1
                guard let pdfPage = pdfDocument.page(at: pageIndex) else { continue }

                if let directText = pdfPage.string,
                   !directText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    rawPagesText[pageNum] = directText
                } else {
                    let recognizedText = try await recognizeTextFromVision(pdfPage: pdfPage)
                    rawPagesText[pageNum] = recognizedText
                }

                let progress = Double(pageNum) / Double(pdfDocument.pageCount)
                onProgress?(progress)
            }

            return rawPagesText
        }

        // 4. PATH GAMBAR MURNI (.jpg, .png, .heic, dll)
        if let uiImage = UIImage(contentsOfFile: url.path),
           let cgImage = uiImage.cgImage {
            print("[VisionOCR] Processing as image: \(url.lastPathComponent)")
            let recognizedText = try await recognizeTextFromCGImage(cgImage)
            print("[VisionOCR] Image OCR result: \(recognizedText.count) chars")
            onProgress?(1.0)
            return [1: recognizedText]
        }

        // 5. Throw Error jika bukan format yang didukung
        throw OCRError.unsupportedFormat
    }
    
    // MARK: - Helper Vision OCR dari PDF Page
    private func recognizeTextFromVision(pdfPage: PDFPage) async throws -> String {
        let pageRect = pdfPage.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        
        let uiImage = renderer.image { context in
            UIColor.white.set()
            context.fill(pageRect)
            context.cgContext.translateBy(x: 0, y: pageRect.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            pdfPage.draw(with: .mediaBox, to: context.cgContext)
        }
        
        guard let cgImage = uiImage.cgImage else {
            throw OCRError.failedToRenderImage
        }
        
        return try await recognizeTextFromCGImage(cgImage)
    }
    
    // MARK: - Helper Vision OCR dari CGImage
    private func recognizeTextFromCGImage(_ cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                // Sort by Y (top-to-bottom), then X (left-to-right) to handle
                // two-column layouts where left column text is read before right column.
                let sortedObservations = observations.sorted { obs1, obs2 in
                    let y1 = obs1.boundingBox.origin.y
                    let y2 = obs2.boundingBox.origin.y
                    let rowTolerance: CGFloat = 0.01 // ~1% page height tolerance for same-row grouping
                    if abs(y1 - y2) <= rowTolerance {
                        return obs1.boundingBox.origin.x < obs2.boundingBox.origin.x
                    }
                    return y1 > y2 // higher Y = top of page (Vision uses bottom-left origin)
                }

                let pageStrings = sortedObservations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: pageStrings.joined(separator: "\n"))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - File Format Detection
    private let wordDocumentType = UTType(importedAs: "org.openxmlformats.wordprocessingml.document")
    private let legacyDocType = UTType(importedAs: "com.microsoft.word.doc")

    /// PK = ZIP archive magic bytes (DOCX is a ZIP)
    private func isZIPArchive(data: Data) -> Bool {
        guard data.count >= 2 else { return false }
        return data[0] == 0x50 && data[1] == 0x4B
    }

    private func isWordDocument(url: URL) -> Bool {
        if url.pathExtension.lowercased() == "docx" { return true }
        return (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType?.conforms(to: wordDocumentType) ?? false
    }

    private func isLegacyDoc(url: URL) -> Bool {
        if url.pathExtension.lowercased() == "doc" { return true }
        return (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType?.conforms(to: legacyDocType) ?? false
    }
}
