//
//  ScriptImportPipelineService.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import Foundation
import SwiftData

public final class ScriptImportPipelineService: ScriptImportPipelineServiceProtocol {
    public var onPhaseChange: ((ProcessingPhase) -> Void)?
    public var onScriptReady: ((Script) -> Void)?
    public var onError: ((String) -> Void)?

    private let ocrService: VisionOCRServiceProtocol
    private let parserService: ScriptParserServiceProtocol
    private let thumbnailService: ThumbnailServiceProtocol
    private let repository: ScriptRepositoryProtocol

    private var processingTask: Task<Void, Never>?

    public init(
        ocrService: VisionOCRServiceProtocol,
        parserService: ScriptParserServiceProtocol,
        thumbnailService: ThumbnailServiceProtocol,
        repository: ScriptRepositoryProtocol
    ) {
        self.ocrService = ocrService
        self.parserService = parserService
        self.thumbnailService = thumbnailService
        self.repository = repository
    }

    public func processFile(at url: URL, title: String) async {
        guard url.startAccessingSecurityScopedResource() else {
            onPhaseChange?(.error(message: "Tidak dapat mengakses file."))
            return
        }

        defer { url.stopAccessingSecurityScopedResource() }

        // Step 1: OCR
        onPhaseChange?(.ocr)

        let rawPagesText: [Int: String]
        do {
            rawPagesText = try await ocrService.extractText(from: url) { _ in }
        } catch {
            onPhaseChange?(.error(message: "Gagal mengekstrak teks."))
            return
        }

        // Step 2: Parsing
        let totalPages = rawPagesText.count
        onPhaseChange?(.parsing(current: 0, total: totalPages))

        let script: Script
        do {
            script = try await parserService.parseScript(
                rawPagesText: rawPagesText,
                scriptTitle: title,
                sourceFileName: url.lastPathComponent
            ) { [weak self] currentPage, pageTotal in
                self?.onPhaseChange?(.parsing(current: currentPage, total: pageTotal))
            }
        } catch {
            onPhaseChange?(.error(message: "Gagal menganalisis naskah."))
            return
        }

        // Step 3: Thumbnail
        if let thumbnailData = await thumbnailService.generateThumbnail(from: url) {
            script.thumbnailData = thumbnailData
        }

        // Step 4: Save
        onPhaseChange?(.saving)

        do {
            try await repository.save(script: script)
        } catch {
            onPhaseChange?(.error(message: "Gagal menyimpan naskah."))
            return
        }

        // Success
        onPhaseChange?(.success(scriptId: script.id, scriptTitle: script.title))
        onScriptReady?(script)
    }

    public func cancel() {
        processingTask?.cancel()
        processingTask = nil
    }
}
