import Foundation
import Observation
import UIKit

@MainActor
@Observable
public final class HomeViewModel {
    public var recentScripts: [Script] = []
    public var isLoading = false
    public var isImporting = false
    public var errorMessage: String?
    
    public var onSelectScript: ((UUID) -> Void)?
    public var onImportTapped: (() -> Void)?
    public var onLibraryTapped: (() -> Void)?
    
    private let repository: ScriptRepositoryProtocol?
    private let ocrService: VisionOCRServiceProtocol?
    private let parserService: ScriptParserServiceProtocol?
    
    public init(
        repository: ScriptRepositoryProtocol? = nil,
        ocrService: VisionOCRServiceProtocol? = nil,
        parserService: ScriptParserServiceProtocol? = nil
    ) {
        self.repository = repository ?? DIContainer.shared.scriptRepository
        self.ocrService = ocrService ?? DIContainer.shared.ocrService
        self.parserService = parserService ?? DIContainer.shared.parserService
    }
    
    public func fetchRecentScripts() async {
        guard let repository else {
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            recentScripts = try await repository.fetchRecentScripts(limit: 5)
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
    
    public func handleSelectedFile(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            Task { [weak self] in
                guard let self else { return }
                guard url.startAccessingSecurityScopedResource() else {
                    await MainActor.run {
                        self.errorMessage = "Tidak dapat mengakses file yang dipilih."
                    }
                    return
                }
                
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                await self.parseAndSave(url: url)
            }
        case .failure(let error):
            if let cocoaError = error as? CocoaError, cocoaError.code == .userCancelled {
                return
            }
            
            errorMessage = error.localizedDescription
        }
    }
    
    private func parseAndSave(url: URL) async {
        guard let ocrService, let parserService else {
            errorMessage = "Layanan impor belum dikonfigurasi."
            return
        }
        
        isImporting = true
        defer { isImporting = false }
        
        do {
            let rawPagesText = try await ocrService.extractText(from: url, onProgress: nil)
            
            // Proses OCR Info Voiceover
            let pageCount = rawPagesText.count
            UIAccessibility.post(
                notification: .announcement,
                argument: "\(pageCount) halaman naskah berhasil dipindai, memproses format..."
            )
            
            // Parser Service
            
            let script = try await parserService.parseScript(
                rawPagesText: rawPagesText,
                scriptTitle: url.deletingPathExtension().lastPathComponent,
                sourceFileName: url.lastPathComponent
            )
            
            // Simpan kalau repository sudah ada
            if let repository {
                try await repository.save(script: script)
            } else {
                print("Repository belum diimplementasi - skip save")
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
