//
//  VisionOCRService.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 27/08/26.
//

import Foundation
import PDFKit
import UIKit
import Vision

public final class VisionOCRService: VisionOCRServiceProtocol {
    
    public init() {}
    
    public func extractText(
        from url: URL,
        onProgress: ((Double) -> Void)?
    ) async throws -> [Int: String] {
        // 1. PATH PDF (Digital & Scanned PDF)
        if let pdfDocument = PDFDocument(url: url) {
            let totalPages = pdfDocument.pageCount
            guard totalPages > 0 else {
                throw OCRError.emptyPageText
            }
            
            var rawPagesText: [Int: String] = [:]
            
            for pageIndex in 0..<totalPages {
                let pageNum = pageIndex + 1
                guard let pdfPage = pdfDocument.page(at: pageIndex) else { continue }
                
                // FAST PATH: PDF berbasis teks digital
                if let directText = pdfPage.string,
                   !directText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    rawPagesText[pageNum] = directText
                } else {
                    // FALLBACK PATH: Vision OCR jika PDF berbasis gambar/scan
                    let recognizedText = try await recognizeTextFromVision(pdfPage: pdfPage)
                    rawPagesText[pageNum] = recognizedText
                }
                
                let progress = Double(pageNum) / Double(totalPages)
                onProgress?(progress)
            }
            
            return rawPagesText
        }
        
        // 2. PATH GAMBAR MURNI (.jpg, .png, dll)
        if let uiImage = UIImage(contentsOfFile: url.path),
           let cgImage = uiImage.cgImage {
            let recognizedText = try await recognizeTextFromCGImage(cgImage)
            onProgress?(1.0)
            return [1: recognizedText]
        }
        
        // 3. Throw Error jika bukan PDF maupun Gambar yang valid
        throw OCRError.pdfCorrupted
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
}
