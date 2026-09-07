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
            expectedCharacters: ["PRIA", "8. WANITA"]
        )
    }

    // MARK: - Test Case 2: Scanned/Image PDF
    func testParseScannedImagePDF() async throws {
        try await assertScriptParsing(
            fileName: "ruangtungguimgpdf",
            fileExtension: "pdf",
            scriptTitle: "Ruang Tunggu",
            expectedCharacters: ["PRIA", "8. WANITA"]
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

    // MARK: - Test Case 5: Page metadata set on blocks
    func testPageMetadataSetOnBlocks() async throws {
        let rawPages: [Int: String] = [
            1: "BAGIAN PERTAMA\n\nPRIA : Ini dialog halaman satu.",
            2: "WANITA : Ini dialog halaman dua."
        ]

        let script = try await parserService.parseScript(
            rawPagesText: rawPages,
            scriptTitle: "Test Script",
            sourceFileName: "test.txt"
        )

        let allBlocks = script.pages.flatMap { $0.blocks }

        for block in allBlocks {
            XCTAssertNotNil(block.startPageNumber, "Block must have startPageNumber")
            XCTAssertGreaterThan(block.startPageNumber ?? 0, 0, "Block must have valid startPageNumber")
        }

        // Verify blocks from page 1 have startPageNumber=1
        let page1Blocks = script.pages.first { $0.pageNumber == 1 }?.blocks ?? []
        for block in page1Blocks {
            XCTAssertEqual(block.startPageNumber, 1, "Page 1 blocks should have startPageNumber=1")
        }

        // Verify blocks from page 2 have startPageNumber=2
        let page2Blocks = script.pages.first { $0.pageNumber == 2 }?.blocks ?? []
        for block in page2Blocks {
            XCTAssertEqual(block.startPageNumber, 2, "Page 2 blocks should have startPageNumber=2")
        }
    }

    // MARK: - Test Case 6: Multi-chunk preserves global orderIndex
    func testMultiChunkPreservesOrderIndex() async throws {
        // Simulate 8 pages to force at least 2 chunks (chunkSize=4)
        var rawPages: [Int: String] = [:]
        for i in 1...8 {
            rawPages[i] = "BAGIAN \(i)\n\nPRIA : Dialog halaman \(i)."
        }

        let script = try await parserService.parseScript(
            rawPagesText: rawPages,
            scriptTitle: "Test Multi-Chunk",
            sourceFileName: "test.txt"
        )

        let allBlocks = script.pages.flatMap { $0.blocks }
        XCTAssertFalse(allBlocks.isEmpty, "Should produce blocks")

        // Verify all orderIndex values are unique and sequential
        let orderIndices = allBlocks.map { $0.orderIndex }.sorted()
        let expectedIndices = Array(1...allBlocks.count)
        XCTAssertEqual(orderIndices, expectedIndices, "OrderIndex must be sequential 1..N")
    }
}
