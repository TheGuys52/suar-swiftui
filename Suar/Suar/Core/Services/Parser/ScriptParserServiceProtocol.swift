//
//  ScriptParserServiceProtocol.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import Foundation

public protocol ScriptParserServiceProtocol: Sendable {
    /// Mengklasifikasikan teks mentah hasil OCR per halaman menjadi entitas halaman dan blok dialog terstruktur[cite: 1].
    /// - Parameters:
    ///   - rawPagesText: Dictionary hasil ekstraksi Vision OCR (PageNumber: RawText)[cite: 1].
    ///   - scriptTitle: Judul naskah yang diparsing[cite: 1].
    ///   - sourceFileName: Nama file asli[cite: 1].
    /// - Returns: Entitas `Script` utuh yang berisi `[ScriptPage]` dan `[ScriptBlock]` siap disimpan[cite: 1].
    func parseScript(
        rawPagesText: [Int: String],
        scriptTitle: String,
        sourceFileName: String
    ) async throws -> Script
}

// TODO: [@Team-Parser / Issue #2] Buat file `ScriptParserService.swift`[cite: 1, 2].
// Pisahkan baris naskah menjadi kategori `.sceneHeader`, `.characterName`, `.dialogue`, atau `.stageDirection`[cite: 1].
// Hubungkan relasi objek Script -> ScriptPage -> ScriptBlock dengan orderIndex yang tepat[cite: 1].
