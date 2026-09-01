import Foundation
import Observation
import SwiftData

/// Represents a single line of a script as rendered on screen.
public struct ScriptLine: Identifiable {
    public let id: UUID
    public let characterName: String?
    public let cueDescription: String?
    public let content: String
    public let type: ScriptLineType

    public init(
        id: UUID = UUID(),
        characterName: String? = nil,
        cueDescription: String? = nil,
        content: String,
        type: ScriptLineType
    ) {
        self.id = id
        self.characterName = characterName
        self.cueDescription = cueDescription
        self.content = content
        self.type = type
    }
}

public enum ScriptLineType {
    case dialogue
    case description
    case title
    case character
    case transition
}

@MainActor
@Observable
public final class ScriptPageViewModel {
    public var scriptTitle: String = ""
    public var currentPageNumber: Int = 1
    public var totalPages: Int = 1
    public var lines: [ScriptLine] = []
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

    init(mockData: ScriptMock) {
        self.injectedRepository = nil
        loadMockData(from: mockData)
    }

    public init() {
        self.injectedRepository = nil
        loadMockData(from: scriptMock)
    }

    public func goToNextPage() {
        guard currentPageNumber < totalPages else { return }
        currentPageNumber += 1
        loadLinesForCurrentPage()
        persistCurrentPage()
    }

    public func goToPreviousPage() {
        guard currentPageNumber > 1 else { return }
        currentPageNumber -= 1
        loadLinesForCurrentPage()
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
            loadLinesForCurrentPage()
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }

    private func loadMockData(from mock: ScriptMock) {
        scriptTitle = mock.title
        totalPages = mock.pages.count
        loadLinesFromMock()
    }

    private func loadLinesForCurrentPage() {
        if currentScript != nil {
            loadLinesFromRealScript()
        } else {
            loadLinesFromMock()
        }
    }

    private func loadLinesFromRealScript() {
        guard let script = currentScript else { lines = []; return }
        let sortedPages = script.pages.sorted { $0.pageNumber < $1.pageNumber }
        guard let page = sortedPages.first(where: { $0.pageNumber == currentPageNumber }) else {
            lines = []; return
        }
        lines = page.blocks
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { block in
                ScriptLine(
                    id: block.id,
                    characterName: block.characterName,
                    cueDescription: block.cueDescription,
                    content: block.content,
                    type: mapBlockTypeToLineType(block.blockType)
                )
            }
    }

    private func loadLinesFromMock() {
        guard let page = scriptMock.pages.first(where: { $0.pageNumber == currentPageNumber }) else {
            lines = []
            return
        }

        lines = page.elements
            .sorted { $0.order < $1.order }
            .compactMap { element -> ScriptLine? in
                switch element.type {
                case .dialogue:
                    return parseDialogue(element.content)
                case .description:
                    return ScriptLine(content: element.content, type: .description)
                case .text:
                    return ScriptLine(content: element.content, type: .title)
                }
            }
    }

    private func mapBlockTypeToLineType(_ blockType: ScriptBlockType) -> ScriptLineType {
        switch blockType {
        case .sceneHeader:   return .title
        case .characterName: return .character
        case .dialogue:      return .dialogue
        case .stageDirection: return .description
        case .parenthetical: return .dialogue
        case .transition:   return .transition
        }
    }

    private func persistCurrentPage() {
        guard let script = currentScript else { return }
        Task { try? await repository?.updateLastReadPage(scriptId: script.id, pageNumber: currentPageNumber) }
    }

    private func parseDialogue(_ content: String) -> ScriptLine {
        let pattern = #"^(.+?):\s*(?:\(([^)]+)\))?\s*(.*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(
                  in: content,
                  options: [],
                  range: NSRange(content.startIndex..., in: content)
              ) else {
            return ScriptLine(content: content, type: .dialogue)
        }

        guard let characterRange = Range(match.range(at: 1), in: content),
              let textRange = Range(match.range(at: 3), in: content) else {
            return ScriptLine(content: content, type: .dialogue)
        }

        let cueRange = match.range(at: 2).location != NSNotFound
            ? Range(match.range(at: 2), in: content)
            : nil

        let characterName = String(content[characterRange])
        let cueDescription = cueRange.map { String(content[$0]) }
        let dialogueText = String(content[textRange])

        return ScriptLine(
            characterName: characterName,
            cueDescription: cueDescription,
            content: dialogueText,
            type: .dialogue
        )
    }
}
