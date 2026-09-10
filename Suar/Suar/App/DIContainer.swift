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
    var audioNoteRepository: AudioNoteRepository?
    public lazy var ocrService: VisionOCRServiceProtocol = VisionOCRService()
    public lazy var parserService: ScriptParserServiceProtocol = ScriptParserService()
    public lazy var scriptParserService: ScriptParserServiceProtocol = {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "LLM_OLAGON_API_KEY") as? String ?? ""
        return AIScriptParserService(apiKey: apiKey)
    }()

    public lazy var thumbnailService: ThumbnailServiceProtocol = ThumbnailService()
    public lazy var seederService: ScriptSeederServiceProtocol = {
        guard let repo = scriptRepository else {
            fatalError("DIContainer.scriptRepository must be set before accessing seederService")
        }
        return ScriptSeederService(repository: repo)
    }()
    public lazy var importPipelineService: ScriptImportPipelineServiceProtocol = {
        guard let repo = scriptRepository else {
            fatalError("DIContainer.scriptRepository must be set before accessing importPipelineService")
        }
        return ScriptImportPipelineService(
            ocrService: ocrService,
            parserService: scriptParserService,
            thumbnailService: thumbnailService,
            repository: repo
        )
    }()

    private init() {}

    @MainActor
    public func configure(modelContext: ModelContext) {
        if scriptRepository != nil { return }
        scriptRepository = ScriptRepository(modelContext: modelContext)
        audioNoteRepository = AudioNoteRepository(container: modelContext.container)
    }
}
