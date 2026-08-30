//
//  VisionOCRService.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 27/08/26.
//

import Foundation
import PDFKit
import Vision

public final class VisionOCRService: VisionOCRServiceProtocol {
    
    public init() {}
    
    public func extractText(
        from url: URL,
        onProgress: ((Double) -> Void)?
    ) async throws -> [Int: String] {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw OCRError.pdfCorrupted
        }
        
        let totalPages = pdfDocument.pageCount
        guard totalPages > 0 else {
            throw OCRError.emptyPageText
        }
        
        var rawPagesText: [Int: String] = [:]
        
        for pageIndex in 0..<totalPages {
            let pageNum = pageIndex + 1
            guard let pdfPage = pdfDocument.page(at: pageIndex) else { continue }
            
            // 1. FAST PATH: Ambil langsung jika PDF berbasis teks digital
            if let directText = pdfPage.string,
               !directText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                rawPagesText[pageNum] = directText
            } else {
                // 2. FALLBACK PATH: Render CGImage & Vision OCR jika PDF murni Scan/Gambar
                let recognizedText = try await recognizeTextFromVision(pdfPage: pdfPage)
                rawPagesText[pageNum] = recognizedText
            }
            
            // Kirim callback progress real-time ke UI
            let progress = Double(pageNum) / Double(totalPages)
            onProgress?(progress)
        }
        
        return rawPagesText
    }
    
    // MARK: - Helper Vision OCR Visual Processing
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
                
                let pageStrings = observations.compactMap { observation in
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
