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
        onProgress: ((Double) -> Void)? = nil
    ) async throws -> [Int: String] {
        // Deteksi jenis file (PDF atau Gambar)
        let pathExtension = url.pathExtension.lowercased()
        
        if pathExtension == "pdf" {
            return try await processPDF(at: url, onProgress: onProgress)
        } else {
            // Gambar tunggal (.png, .jpg, .jpeg)
            let rawText = try await processImage(at: url)
            return [1: rawText]
        }
    }
    
    // MARK: - PDF Processing
    private func processPDF(
        at url: URL,
        onProgress: ((Double) -> Void)?
    ) async throws -> [Int: String] {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw NSError(domain: "VisionOCRService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Gagal membuka dokumen PDF."])
        }
        
        let pageCount = pdfDocument.pageCount
        var pageResults: [Int: String] = [:]
        
        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            // Render PDFPage ke CGImage resolusi tinggi
            let pageBounds = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageBounds.size)
            let uiImage = renderer.image { context in
                UIColor.white.set()
                context.fill(pageBounds)
                context.cgContext.translateBy(x: 0, y: pageBounds.height)
                context.cgContext.scaleBy(x: 1.0, y: -1.0)
                page.draw(with: .mediaBox, to: context.cgContext)
            }
            
            guard let cgImage = uiImage.cgImage else { continue }
            
            // Ekstrak teks via Vision
            let pageText = try await recognizeText(from: cgImage)
            pageResults[pageIndex + 1] = pageText
            
            // Update progress callback
            let progress = Double(pageIndex + 1) / Double(pageCount)
            onProgress?(progress)
        }
        
        return pageResults
    }
    
    // MARK: - Single Image Processing
    private func processImage(at url: URL) async throws -> String {
        guard let uiImage = UIImage(contentsOfFile: url.path),
              let cgImage = uiImage.cgImage else {
            throw NSError(domain: "VisionOCRService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Gagal memuat file gambar."])
        }
        return try await recognizeText(from: cgImage)
    }
    
    // MARK: - Vision Text Recognition Engine
    private func recognizeText(from cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                // Gabungkan seluruh baris teks berdasarkan urutan baca dari atas ke bawah
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }
            
            // Konfigurasi Vision untuk hasil ekstraksi teks yang paling akurat
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
