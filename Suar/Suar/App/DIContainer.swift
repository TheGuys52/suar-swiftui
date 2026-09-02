//  DIContainer.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import Foundation
import SwiftData

public final class DIContainer: @unchecked Sendable {
    public static let shared: DIContainer = DIContainer()

    public var scriptRepository: ScriptRepositoryProtocol?
    public lazy var ocrService: VisionOCRServiceProtocol = VisionOCRService()
    public lazy var parserService: ScriptParserServiceProtocol = ScriptParserService()
    lazy var scriptParserService: ScriptParserServiceProtocol = {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "LLM_OLAGON_API_KEY") as? String ?? ""
        return AIScriptParserService(apiKey: apiKey)
    }()

    private init() {}

    public func configure(modelContext: ModelContext) {
        if scriptRepository != nil { return }
        scriptRepository = ScriptRepository(modelContext: modelContext)
    }
}
