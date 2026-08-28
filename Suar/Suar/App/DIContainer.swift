//
//  DIContainer.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import Foundation
import SwiftData

@MainActor
public final class DIContainer {
    public static let shared: DIContainer = DIContainer()
    
    // MARK: - Core Services & Repositories
    // TODO: [@Team-All] Ganti placeholder nil dengan implementasi konkrit setelah Service/Repo selesai dibuat[cite: 2]
    public var scriptRepository: ScriptRepositoryProtocol?
    public var ocrService: VisionOCRServiceProtocol? = VisionOCRService()
    public var parserService: ScriptParserServiceProtocol? = ScriptParserService()
    
    private init() {}
    
    // MARK: - Setup
    public func configure(modelContext: ModelContext) {
        // TODO: [@Team-All] Inisialisasi ScriptRepository(modelContext: modelContext)
        // TODO: [@Team-OCR] Inisialisasi VisionOCRService()
        // TODO: [@Team-Parser] Inisialisasi ScriptParserService()
    }
}
