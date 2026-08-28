//
//  VisionOCRService.swift
//  Suar
//
//  Created by Adiat Rahman on 27/08/26.
//

import Foundation
import PDFKit
import UIKit
import Vision

public struct VisionOCRService: VisionOCRServiceProtocol {
    public init() {}
    
    public func extractText(from fileURL: URL, onProgress: (@Sendable (Double) -> Void)?) async throws -> [Int: String] {
        
        // Deteksi Tipe File (PDF atau Gambar)
        let resourceValues = try fileURL.resourceValues(forKeys: [.contentTypeKey])
        let contentType = resourceValues.contentType
        
        if contentType == .pdf {
            // PDF
            guard let pdfDocument = PDFDocument(url: fileURL) else {
                throw OCRError.cannotOpenDocument
            }
            
            // PDF Ketikan
            if let directText = pdfDocument.string, !directText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return [1: directText]
            }
            
            // PDF Gambar
            let pageCount = pdfDocument.pageCount
            var results: [Int: String] = [:]
            
            // Iterasi Per Halaman
            for pageIndex in 0..<pageCount {
                guard let pdfPage = pdfDocument.page(at: pageIndex) else {
                    continue
                }
                
                // Render ke UIImage
                let pageRect = pdfPage.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                let image = renderer.image { ctx in
                    UIColor.white.setFill()
                    ctx.fill(pageRect)
                    ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                    ctx.cgContext.scaleBy(x: 1, y: -1)
                    pdfPage.draw(with: .mediaBox, to: ctx.cgContext)
                }
                
                // OCR Jalan di PDF
                let pageNumber = pageIndex + 1
                let text = try await performOCR(on: image)
                results[pageNumber] = text
                
                // Progress
                let progress = Double(pageNumber) / Double(pageCount)
                onProgress?(progress)
            }
            
            return results
            
        } else {
            // Gambar
            guard let image = UIImage(contentsOfFile: fileURL.path) else {
                throw OCRError.cannotLoadImage
            }
            
            let text = try await performOCR(on: image)
            onProgress?(1.0)
            
            return [1: text]
        }
        
//        return [:]
    }
    
    private func performOCR(on image: UIImage) async throws -> String {
        // Ekstrak Data Piksel dari UIImage
        guard let cgImage = image.cgImage else {
            throw OCRError.cannotConvertImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Request untuk membaca text
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // Bounding box berisi teks dan info posisi teks
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let texts = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let result = texts.joined(separator: "\n")
                continuation.resume(returning: result)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false // Koreksi?
            
            // Eksekusi Request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
