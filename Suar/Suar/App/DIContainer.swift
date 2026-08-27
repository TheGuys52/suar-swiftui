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
    public var scriptRepository: ScriptRepositoryProtocol?
    public lazy var ocrService: VisionOCRServiceProtocol = VisionOCRService()
    public lazy var parserService: ScriptParserServiceProtocol = ScriptParserService()
    
    private init() {}
    
    // MARK: - Setup
    public func configure(modelContext: ModelContext) {
        // TODO: [@Team-All] Inisialisasi ScriptRepository(modelContext: modelContext)
        // TODO: [@Team-OCR] Inisialisasi VisionOCRService()
        // TODO: [@Team-Parser] Inisialisasi ScriptParserService()
    }
}
