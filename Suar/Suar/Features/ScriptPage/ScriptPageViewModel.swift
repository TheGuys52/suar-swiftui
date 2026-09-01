import Foundation
import Observation
import SwiftData

@MainActor
@Observable
public final class ScriptPageViewModel {
    public var scriptTitle: String = ""
    public var currentPageNumber: Int = 1
    public var totalPages: Int = 1
    public var blocks: [ScriptBlock] = []
    public var onBack: (() -> Void)?
    public private(set) var currentScript: Script?
    public var isLoading: Bool = false
    public var errorMessage: String?

    private let injectedRepository: ScriptRepositoryProtocol?

    private var repository: ScriptRepositoryProtocol? {
        injectedRepository ?? DIContainer.shared.scriptRepository
    }

    public init(scriptId: UUID, repository: ScriptRepositoryProtocol? = nil) {
        self.injectedRepository = repository
        self.isLoading = true
        Task { await loadScript(id: scriptId) }
    }

    public init() {
        self.injectedRepository = nil
    }

    public func goToNextPage() {
        guard currentPageNumber < totalPages else { return }
        currentPageNumber += 1
        loadBlocksForCurrentPage()
        persistCurrentPage()
    }

    public func goToPreviousPage() {
        guard currentPageNumber > 1 else { return }
        currentPageNumber -= 1
        loadBlocksForCurrentPage()
        persistCurrentPage()
    }

    public func didTapBack() {
        onBack?()
    }

    private func loadScript(id: UUID) async {
        guard let repository else {
            errorMessage = "Repository belum dikonfigurasi."
            isLoading = false
            return
        }

        do {
            guard let script = try await repository.fetchScript(by: id) else {
                errorMessage = "Naskah tidak ditemukan."
                isLoading = false
                return
            }

            self.currentScript = script
            self.scriptTitle = script.title
            self.totalPages = script.pages.count
            self.currentPageNumber = script.lastReadPage
            self.isLoading = false
            self.errorMessage = nil
            loadBlocksForCurrentPage()
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }

    private func loadBlocksForCurrentPage() {
        guard let script = currentScript else { blocks = []; return }
        let sortedPages = script.pages.sorted { $0.pageNumber < $1.pageNumber }
        guard let page = sortedPages.first(where: { $0.pageNumber == currentPageNumber }) else {
            blocks = []
            return
        }
        blocks = page.blocks.sorted { $0.orderIndex < $1.orderIndex }
    }

    private func persistCurrentPage() {
        guard let script = currentScript else { return }
        Task { try? await repository?.updateLastReadPage(scriptId: script.id, pageNumber: currentPageNumber) }
    }
}
