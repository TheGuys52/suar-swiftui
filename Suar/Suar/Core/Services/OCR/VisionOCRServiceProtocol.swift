//
//  VisionOCRServiceProtocol.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import Foundation

public protocol VisionOCRServiceProtocol: Sendable {
    /// Mengekstrak teks mentah per halaman dari dokumen naskah (PDF atau Gambar)
    /// - Parameters:
    ///   - fileURL: URL lokal file PDF/Gambar yang dipilih pengguna
    ///   - onProgress: Closure callback untuk memantau progres ekstraksi (0.0 sampai 1.0).
    /// - Returns: Dictionary dengan Key = Nomor Halaman (dimulai dari 1), Value = Teks mentah halaman tersebut
    func extractText(
        from fileURL: URL,
        onProgress: (@Sendable (Double) -> Void)?
    ) async throws -> [Int: String]
}

// TODO: [@Team-OCR / Issue #1] Buat file `VisionOCRService.swift`
// Gunakan `VNRecognizeTextRequest` dari Apple Vision Framework
// Jika file adalah PDF, iterasi `PDFDocument` per halaman, render ke `CGImage`, lalu jalankan Vision OCR
