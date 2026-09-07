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

    // MARK: - Edit State
    public var isEditing: Bool = false
    public var editingBlockId: UUID?
    public var editingTexts: [UUID: String] = [:]
    public var editingCueDescriptions: [UUID: String?] = [:]
    private var savedBlocks: [UUID: (content: String, cueDescription: String?)] = [:]

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
            for block in page.blocks where block.content.localizedCaseInsensitiveContains(query) {
                searchResults.append(SearchResult(blockId: block.id, pageNumber: page.pageNumber))
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

    // MARK: - Edit Mode
    public func toggleEditMode() {
        if isEditing {
            // Cancel edit mode without saving
            cancelEditing()
        } else {
            // Enter edit mode - save current state
            isEditing = true
            editingBlockId = nil
            editingTexts = [:]
            editingCueDescriptions = [:]
            savedBlocks = [:]
            for block in blocks {
                savedBlocks[block.id] = (content: block.content, cueDescription: block.cueDescription)
                editingTexts[block.id] = block.content
                editingCueDescriptions[block.id] = block.cueDescription
            }
        }
    }

    public func selectBlockForEditing(_ blockId: UUID) {
        editingBlockId = blockId
    }

    public func deselectBlock() {
        editingBlockId = nil
    }

    public func updateEditingText(for blockId: UUID, text: String) {
        editingTexts[blockId] = text
    }

    public func updateEditingCueDescription(for blockId: UUID, text: String?) {
        editingCueDescriptions[blockId] = text
    }

    public func saveEdits() async {
        guard isEditing else { return }

        for block in blocks {
            guard let newContent = editingTexts[block.id] else { continue }
            let newCue = editingCueDescriptions[block.id] ?? block.cueDescription

            // Only save if content actually changed
            if newContent != block.content || newCue != block.cueDescription {
                try? await repository?.updateBlock(blockId: block.id, content: newContent, cueDescription: newCue)
            }
        }

        isEditing = false
        editingBlockId = nil
        editingTexts = [:]
        editingCueDescriptions = [:]
        savedBlocks = [:]
        loadBlocksForCurrentPage()
    }

    public func cancelEditing() {
        isEditing = false
        editingBlockId = nil
        editingTexts = [:]
        editingCueDescriptions = [:]
        // Restore saved state
        for block in blocks {
            if let saved = savedBlocks[block.id] {
                block.content = saved.content
                block.cueDescription = saved.cueDescription
            }
        }
        savedBlocks = [:]
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
