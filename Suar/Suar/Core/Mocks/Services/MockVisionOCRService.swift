//
//  MockVisionOCRService.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 27/08/26.
//

import Foundation

public final class MockVisionOCRService: VisionOCRServiceProtocol {
    public var stubbedResult: [Int: String] = [
        1: """
        Bagian Pertama
        
        HAL YANG PERTAMA MUNCUL ADALAH SUARA ORANG-ORANG: KERAMAIAN.
        
        1. PRIA : (mengelus dada) Ya Tuhan. Oh ya Tuhaan.
        """
    ]
    public var shouldThrowError: Bool = false
    
    public init() {}
    
    public func extractText(
        from url: URL,
        onProgress: ((Double) -> Void)? = nil
    ) async throws -> [Int: String] {
        if shouldThrowError {
            throw NSError(domain: "MockOCRService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock OCR Error"])
        }
        onProgress?(1.0)
        return stubbedResult
    }
}
