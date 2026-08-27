//
//  ScriptOCRParserTests.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 27/08/26.
//

@testable import Suar
import XCTest

final class ScriptOCRParserTests: XCTestCase {
    
    var ocrService: VisionOCRServiceProtocol!
    var parserService: ScriptParserServiceProtocol!
    
    override func setUp() {
        super.setUp()
        ocrService = VisionOCRService()
        parserService = ScriptParserService()
    }
    
    override func tearDown() {
        ocrService = nil
        parserService = nil
        super.tearDown()
    }
    
    func testParseRuangTungguPDF() async throws {
        // 1. Dapatkan URL file pdf dari Bundle Utama
        guard let pdfURL = Bundle.main.url(forResource: "ruangtunggu", withExtension: "pdf") else {
            XCTFail("File ruangtunggu.pdf tidak ditemukan di Bundle.main")
            return
        }
        
        // 2. Eksekusi OCR
        let rawPagesText = try await ocrService.extractText(from: pdfURL, onProgress: nil)
        XCTAssertFalse(rawPagesText.isEmpty, "Hasil ekstraksi teks OCR tidak boleh kosong")
        
        // 3. Eksekusi Parser
        let script = try await parserService.parseScript(
            rawPagesText: rawPagesText,
            scriptTitle: "Ruang Tunggu",
            sourceFileName: "ruangtunggu.pdf"
        )
        
        // 4. Verifikasi Hasil Parsing
        XCTAssertEqual(script.title, "Ruang Tunggu")
        XCTAssertGreaterThan(script.pages.count, 0, "Jumlah halaman harus lebih dari 0")
        
        let allBlocks = script.pages.flatMap { $0.blocks }
        XCTAssertGreaterThan(allBlocks.count, 0, "Jumlah blok naskah harus terisi")
        
        // Memastikan tokoh PRIA dan WANITA terdeteksi di dalam blok dialog
        let characterNames = Set(allBlocks.compactMap { $0.characterName })
        XCTAssertTrue(characterNames.contains("PRIA"), "Harus mendeteksi tokoh PRIA")
        XCTAssertTrue(characterNames.contains("WANITA"), "Harus mendeteksi tokoh WANITA")
        
        // Cetak ringkasan ke Console untuk inspeksi manual
        print("====== HASIL PARSING NASKAH ======")
        print("Judul: \(script.title)")
        print("Total Halaman: \(script.pages.count)")
        print("Total Blok: \(allBlocks.count)")
        print("Daftar Tokoh: \(characterNames)")
        print("Sample Block 1: \(allBlocks.first?.content ?? "")")
        print("=================================")
    }
}
