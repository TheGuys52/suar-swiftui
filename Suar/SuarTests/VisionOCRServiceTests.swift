//
//  VisionOCRServiceTests.swift
//  Suar
//
//  Created by Adiat Rahman on 28/08/26.
//

@testable import Suar
import XCTest

final class VisionOCRServiceTests: XCTestCase {
    var sut: VisionOCRService!
    
    override func setUp() {
        super.setUp()
        sut = VisionOCRService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func test_extractText_bukanPDF() async throws {
        // GIVEN: Ambil sample image dari bundle app
        // Ganti dengan nama file gambar Anda
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "Ruang Tunggu - born", withExtension: "pdf") else {
            XCTFail("Sample file tidak ditemukan di bundle test")
            return
        }

        // WHEN: Jalankan OCR
        let results = try await sut.extractText(from: url, onProgress: nil)

        // THEN: Hasil tidak kosong
        XCTAssertFalse(results.isEmpty, "Hasil OCR tidak boleh kosong")
        XCTAssertEqual(results[1]?.isEmpty ?? true, false, "Halaman 1 tidak boleh kosong")
        print("✅ OCR Test Berhasil!")
        print("Jumlah halaman: \(results.count)")
        for (page, text) in results.sorted(by: { $0.key < $1.key }) {
            print("Halaman \(page): \(text.prefix(100))...")
        }
    }
    
    func test_extractText_imagePDF() async throws {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "Ruang Tunggu - image", withExtension: "pdf") else {
            XCTFail("File Ruang Tunggu - image.pdf tidak ditemukan")
            return
        }

        let results = try await sut.extractText(from: url, onProgress: nil)

        XCTAssertFalse(results.isEmpty, "Hasil OCR tidak boleh kosong")
        print("✅ OCR Image PDF Test Berhasil!")
        print("Jumlah halaman: \(results.count)")
        for (page, text) in results.sorted(by: { $0.key < $1.key }) {
            print("Halaman \(page): \(text.prefix(100))...")
        }
    }
    
    func test_extractText_pureImage() async throws {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "Ruang Tunggu - pureImage2", withExtension: "jpg") else {
            XCTFail("File Ruang Tunggu - pureImage2.jpg tidak ditemukan")
            return
        }

        let results = try await sut.extractText(from: url, onProgress: nil)

        XCTAssertFalse(results.isEmpty, "Hasil OCR tidak boleh kosong")
        print("✅ OCR Pure Image Test Berhasil!")
        print("Jumlah halaman: \(results.count)")
        for (page, text) in results.sorted(by: { $0.key < $1.key }) {
            print("Halaman \(page): \(text.prefix(100))...")
        }
    }
}
