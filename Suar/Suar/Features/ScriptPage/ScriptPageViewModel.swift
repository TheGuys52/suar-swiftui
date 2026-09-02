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
    public var onEdit: (() -> Void)?
    public var onDelete: (() -> Void)?
    public private(set) var currentScript: Script?
    private var scriptId: UUID?
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Search State
    public var isSearching: Bool = false
    public var searchText: String = ""
    public private(set) var searchResults: [SearchResult] = []
    public var currentSearchIndex: Int = 0

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

    // MARK: - Search
    public struct SearchResult: Identifiable {
        public let id = UUID()
        public let blockId: UUID
        public let pageNumber: Int
    }

    public func performSearch(query: String) {
        searchText = query
        searchResults = []
        currentSearchIndex = 0

        guard !query.isEmpty, let script = currentScript else { return }

        for page in script.pages {
            for block in page.blocks {
                if block.content.localizedCaseInsensitiveContains(query) {
                    searchResults.append(SearchResult(blockId: block.id, pageNumber: page.pageNumber))
                }
            }
        }
    }

    public func nextSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex + 1) % searchResults.count
        navigateToCurrentSearchResult()
    }

    public func previousSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex - 1 + searchResults.count) % searchResults.count
        navigateToCurrentSearchResult()
    }

    public func dismissSearch() {
        isSearching = false
        searchText = ""
        searchResults = []
        currentSearchIndex = 0
    }

    public func clearSearchResults() {
        searchResults = []
        currentSearchIndex = 0
    }

    public func performDelete() async {
        guard let id = scriptId else { return }
        try? await repository?.delete(scriptId: id)
    }

    private func navigateToCurrentSearchResult() {
        guard currentSearchIndex < searchResults.count else { return }
        let result = searchResults[currentSearchIndex]
        if result.pageNumber != currentPageNumber {
            currentPageNumber = result.pageNumber
            loadBlocksForCurrentPage()
        }
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
            self.scriptId = script.id
            self.scriptTitle = script.title
            self.totalPages = script.pages.count
            self.currentPageNumber = script.lastReadPage
            self.isLoading = false
            self.errorMessage = nil
            loadBlocksForCurrentPage()
            try await repository.updateLastReadPage(scriptId: script.id, pageNumber: script.lastReadPage)
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
