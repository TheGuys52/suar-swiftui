import Foundation
import Observation

@MainActor
@Observable
public final class HomeViewModel {
    public var recentScripts: [Script] = []
    public var allScripts: [Script] = []
    public var isLoading = false
    public var isImporting = false
    public var errorMessage: String?
    
    public var onSelectScript: ((UUID) -> Void)?
    public var onImportTapped: (() -> Void)?
    public var onLibraryTapped: (() -> Void)?
    /// Callback yang dipanggil saat user menekan "Buka Reader" di success alert. Coordinator menggunakan ini untuk navigasi ke reader.
    public var onOpenScriptReader: ((Script) -> Void)?
    public var progressPercentage: Double = 0.0
    public var progressStatusMessage: String = ""
    public var showSuccessAlert: Bool = false
    public var newlyProcessedScript: Script?
    public var currentScriptTitle: String = ""
    
    private let injectedRepository: ScriptRepositoryProtocol?
    private var repository: ScriptRepositoryProtocol? {
        injectedRepository ?? DIContainer.shared.scriptRepository
    }
    
    private let ocrService: VisionOCRServiceProtocol?
    private let parserService: ScriptParserServiceProtocol
    
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
    /// Otomatis memproses dan menyimpan 'ruangtunggu.pdf' dari Bundle jika database masih kosong.
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
            
            try await repository.save(script: script)
            print("[Auto-Seed] Berhasil men-seed naskah: \(script.title)")
        } catch {
            print("[Auto-Seed] Gagal men-seed PDF: \(error.localizedDescription)")
        }
    }
    #endif
    
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

    public func fetchAllScripts() async {
        guard let repository else {
            return
        }

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
    
    /// Menghandle hasil dari file picker. Jika sukses, memanggil [processSelectedFile] untuk OCR + parse + save.
    /// Jika gagal (misal: user membatalkan), menampilkan error message.
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
    
    /// Menjalankan pipeline OCR + parsing + save. Progress di-update secara real-time (0-70% OCR, 70-90% parsing, 90-100% save).
    /// Pada sukses, menyimpan script dan menampilkan success alert. Pada gagal, menampilkan error message.
    public func processSelectedFile(url: URL) async {
        guard let ocrService, let repository else {
            errorMessage = "Layanan impor belum dikonfigurasi."
            return
        }
        
        isImporting = true
        currentScriptTitle = url.deletingPathExtension().lastPathComponent
        progressPercentage = 0.0
        progressStatusMessage = "Mengekstrak teks dari naskah..."
        defer {
            isImporting = false
            progressPercentage = 0.0
            progressStatusMessage = ""
        }
        
        do {
            // Step 1: Vision OCR (0.0 - 0.70)
            let rawPagesText = try await ocrService.extractText(from: url) { [weak self] ocrProgress in
                Task { @MainActor in
                    self?.progressPercentage = ocrProgress * 0.7
                    self?.progressStatusMessage = "Mengekstrak teks dari halaman..."
                }
            }
            
            // Step 2: Parsing naskah (0.70 - 0.90)
            progressStatusMessage = "Menganalisis struktur naskah..."
            progressPercentage = 0.7
            
            let script = try await parserService.parseScript(
                rawPagesText: rawPagesText,
                scriptTitle: url.deletingPathExtension().lastPathComponent,
                sourceFileName: url.lastPathComponent
            ) { [weak self] currentPage, totalPages in
                Task { @MainActor in
                    let parseRatio = Double(currentPage) / Double(totalPages)
                    self?.progressPercentage = 0.7 + (parseRatio * 0.20)
                    self?.progressStatusMessage = "Menganalisis struktur naskah (halaman \(currentPage)/\(totalPages))..."
                }
            }
            
            // Step 3: Simpan naskah ke repository (0.90 - 1.0)
            progressStatusMessage = "Menyimpan naskah..."
            progressPercentage = 0.9
            
            try await repository.save(script: script)
            await fetchAllScripts()
            progressPercentage = 1.0
            
            newlyProcessedScript = script
            showSuccessAlert = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            newlyProcessedScript = nil
            showSuccessAlert = false
        }
    }
}
