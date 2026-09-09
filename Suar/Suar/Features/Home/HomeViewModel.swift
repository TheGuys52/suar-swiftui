import Foundation
import Observation
import PDFKit
import UIKit

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

    private let injectedRepository: ScriptRepositoryProtocol?
    private var repository: ScriptRepositoryProtocol? {
        injectedRepository ?? DIContainer.shared.scriptRepository
    }

    private let ocrService: VisionOCRServiceProtocol?
    private let parserService: ScriptParserServiceProtocol

    private var processingTask: Task<Void, Never>?
    private var pendingURL: URL?

    public init(
        repository: ScriptRepositoryProtocol? = nil,
        ocrService: VisionOCRServiceProtocol? = nil,
        parserService: ScriptParserServiceProtocol? = nil
    ) {
        self.injectedRepository = repository
        self.ocrService = ocrService ?? DIContainer.shared.ocrService
        self.parserService = parserService ?? DIContainer.shared.scriptParserService
    }

    #if DEBUG
    public func seedSamplePDFIfNeeded() async {
        guard let repository, let ocrService else { return }

        do {
            let existingScripts = try await repository.fetchAllScripts()
            guard existingScripts.isEmpty else { return }

            guard let pdfURL = Bundle.main.url(forResource: "ruangtunggu", withExtension: "pdf") else {
                print("[Auto-Seed] File 'ruangtunggu.pdf' tidak ditemukan di Bundle.")
                return
            }

            let rawPagesText = try await ocrService.extractText(from: pdfURL) { _ in }
            let script = try await parserService.parseScript(
                rawPagesText: rawPagesText,
                scriptTitle: pdfURL.deletingPathExtension().lastPathComponent,
                sourceFileName: pdfURL.lastPathComponent,
                onProgress: nil
            )
            script.thumbnailData = generatePDFThumbnailData(from: pdfURL)

            try await repository.save(script: script)
            print("[Auto-Seed] Berhasil men-seed naskah: \(script.title)")
        } catch {
            print("[Auto-Seed] Gagal men-seed PDF: \(error.localizedDescription)")
        }
    }
    #endif

    public func fetchRecentScripts() async {
        guard let repository else { return }

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
        guard let repository else { return }

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

            processingTask?.cancel()
            processingTask = Task { [weak self] in
                guard let self else { return }
                guard url.startAccessingSecurityScopedResource() else {
                    await MainActor.run {
                        self.processingPhase = .error(message: "Tidak dapat mengakses file.")
                    }
                    return
                }

                await self.processSelectedFile(url: url)
                url.stopAccessingSecurityScopedResource()
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
        processingTask?.cancel()
        processingTask = nil
        pendingURL = nil
        processingPhase = .idle
    }

    private func processSelectedFile(url: URL) async {
        guard let ocrService, let repository else {
            processingPhase = .error(message: "Layanan impor belum dikonfigurasi.")
            return
        }

        // Step 1: OCR
        processingPhase = .ocr

        let rawPagesText: [Int: String]
        do {
            rawPagesText = try await ocrService.extractText(from: url) { [weak self] _ in
                // OCR progress is continuous 0-1, no page granularity exposed
                // State is already .ocr — UI shows "Mengekstrak teks..."
            }
        } catch {
            processingPhase = .error(message: "Gagal mengekstrak teks.")
            return
        }

        // Step 2: Parsing
        let totalPages = rawPagesText.count
        processingPhase = .parsing(current: 0, total: totalPages)

        let script: Script
        do {
            script = try await parserService.parseScript(
                rawPagesText: rawPagesText,
                scriptTitle: url.deletingPathExtension().lastPathComponent,
                sourceFileName: url.lastPathComponent
            ) { [weak self] currentPage, pageTotal in
                Task { @MainActor in
                    self?.processingPhase = .parsing(current: currentPage, total: pageTotal)
                }
            }
        } catch {
            processingPhase = .error(message: "Gagal menganalisis naskah.")
            return
        }

        script.thumbnailData = generatePDFThumbnailData(from: url)

        // Step 3: Save
        processingPhase = .saving

        do {
            try await repository.save(script: script)
        } catch {
            processingPhase = .error(message: "Gagal menyimpan naskah.")
            return
        }

        // Success — show success state then refresh list
        processingPhase = .success(scriptId: script.id, scriptTitle: script.title)

        await fetchAllScripts()
        await fetchRecentScripts()

        // Dismiss success after 3 seconds
        try? await Task.sleep(for: .seconds(3))
        if case .success = processingPhase {
            processingPhase = .idle
        }

        onOpenScriptReader?(script)
        errorMessage = nil
    }

    private func generatePDFThumbnailData(from url: URL) -> Data? {
        let ext = url.pathExtension.lowercased()

        if ext == "docx" || ext == "doc" {
            return nil
        }

        if let pdfDocument = PDFDocument(url: url),
           let pdfPage = pdfDocument.page(at: 0) {
            let thumbnail = pdfPage.thumbnail(of: CGSize(width: 600, height: 360), for: .mediaBox)
            return thumbnail.pngData()
        }

        if let image = UIImage(contentsOfFile: url.path) {
            return image.pngData()
        }

        return nil
    }
}
