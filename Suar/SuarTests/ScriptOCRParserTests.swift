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
    
    // MARK: - Test Case 1: Digital PDF
    func testParseDigitalPDF() async throws {
        try await assertScriptParsing(
            fileName: "ruangtunggu",
            fileExtension: "pdf",
            scriptTitle: "Ruang Tunggu",
            expectedCharacters: ["PRIA", "WANITA"]
        )
    }
    
    // MARK: - Test Case 2: Scanned/Image PDF
    func testParseScannedImagePDF() async throws {
        try await assertScriptParsing(
            fileName: "ruangtungguimgpdf",
            fileExtension: "pdf",
            scriptTitle: "Ruang Tunggu",
            expectedCharacters: ["PRIA", "WANITA"]
        )
    }
    
    // MARK: - Test Case 3: Pure Image JPG
    func testParsePureImage() async throws {
        try await assertScriptParsing(
            fileName: "ruangtunggu-image",
            fileExtension: "jpg",
            scriptTitle: "Ruang Tunggu",
            expectedCharacters: ["PRIA"]
        )
    }
    
    // MARK: - Reusable Helper Assertion Method
    private func assertScriptParsing(
        fileName: String,
        fileExtension: String,
        scriptTitle: String,
        expectedCharacters: Set<String>
    ) async throws {
        // 1. Ambil URL file dari Bundle Test / Bundle Main
        let testBundle = Bundle(for: type(of: self))
        guard let fileURL = testBundle.url(forResource: fileName, withExtension: fileExtension)
                ?? Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            XCTFail("File \(fileName).\(fileExtension) tidak ditemukan di Bundle Test maupun Bundle.main")
            return
        }
        
        // 2. Eksekusi OCR
        let rawPagesText = try await ocrService.extractText(from: fileURL, onProgress: nil)
        XCTAssertFalse(rawPagesText.isEmpty, "Hasil OCR untuk \(fileName).\(fileExtension) tidak boleh kosong")
        
        // 3. Eksekusi Parser
        let script = try await parserService.parseScript(
            rawPagesText: rawPagesText,
            scriptTitle: scriptTitle,
            sourceFileName: "\(fileName).\(fileExtension)"
        )
        
        // 4. Verifikasi Hasil Parsing
        XCTAssertEqual(script.title, scriptTitle)
        XCTAssertGreaterThan(script.pages.count, 0, "Jumlah halaman harus lebih dari 0")
        
        let allBlocks = script.pages.flatMap { $0.blocks }
        XCTAssertGreaterThan(allBlocks.count, 0, "Jumlah blok naskah harus terisi")
        
        // Memastikan tokoh yang diharapkan terdeteksi di dalam blok dialog
        let characterNames = Set(allBlocks.compactMap { $0.characterName })
        for expectedCharacter in expectedCharacters {
            XCTAssertTrue(
                characterNames.contains(expectedCharacter),
                "[\(fileName)] Harus mendeteksi tokoh \(expectedCharacter)"
            )
        }
        
        print("====== HASIL PARSING [\(fileName).\(fileExtension)] ======")
        print("Judul: \(script.title)")
        print("Total Halaman: \(script.pages.count)")
        print("Total Blok: \(allBlocks.count)")
        print("Daftar Tokoh: \(characterNames)")
        print("=========================================================")
    }
}
