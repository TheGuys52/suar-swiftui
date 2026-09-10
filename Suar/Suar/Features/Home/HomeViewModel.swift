//
//  HomeViewModel.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
public final class HomeViewModel {
    public var recentScripts: [Script] = []
    public var allScripts: [Script] = []
    public var isLoading = false
    public var errorMessage: String?

    public var onSelectScript: ((UUID) -> Void)?
    public var onImportTapped: (() -> Void)?
    public var onLibraryTapped: (() -> Void)?
    public var onShowOnboarding: (() -> Void)?
    public var onOpenScriptReader: ((Script) -> Void)?

    public var processingPhase: ProcessingPhase = .idle
    public var currentScriptTitle: String = ""

    private var pipelineService: ScriptImportPipelineServiceProtocol
    private let seederService: ScriptSeederServiceProtocol
    private var pendingURL: URL?

    public init(
        pipelineService: ScriptImportPipelineServiceProtocol? = nil,
        seederService: ScriptSeederServiceProtocol? = nil
    ) {
        self.pipelineService = pipelineService ?? DIContainer.shared.importPipelineService
        self.seederService = seederService ?? DIContainer.shared.seederService
    }

    public func seedIfNeeded() async {
        await seederService.seedIfNeeded()
    }

    public func fetchRecentScripts() async {
        guard let repository = DIContainer.shared.scriptRepository else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            recentScripts = try await repository.fetchRecentScripts(limit: 5)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func fetchAllScripts() async {
        guard let repository = DIContainer.shared.scriptRepository else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            allScripts = try await repository.fetchAllScripts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func didTapScript(id: UUID) {
        onSelectScript?(id)
    }

    public func didTapImport() {
        onImportTapped?()
    }

    public func didTapLibrary() {
        onLibraryTapped?()
    }

    public func didTapShowOnboarding() {
        onShowOnboarding?()
    }

    public func handleSelectedFile(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            pendingURL = url
            currentScriptTitle = url.deletingPathExtension().lastPathComponent

            pipelineService.onPhaseChange = { [weak self] phase in
                self?.processingPhase = phase
            }
            pipelineService.onScriptReady = { [weak self] script in
                self?.onOpenScriptReader?(script)
            }
            pipelineService.onError = { [weak self] message in
                self?.errorMessage = message
            }

            Task {
                await pipelineService.processFile(at: url, title: currentScriptTitle)
                await fetchAllScripts()
                await fetchRecentScripts()
            }
        case .failure(let error):
            if let cocoaError = error as? CocoaError, cocoaError.code == .userCancelled {
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    public func retryLastProcessing() {
        guard let url = pendingURL else { return }
        handleSelectedFile(result: .success(url))
    }

    public func dismissProcessing() {
        pipelineService.cancel()
        pendingURL = nil
        processingPhase = .idle
    }
}
