import Foundation
import Observation

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
}

@MainActor
@Observable
public final class ScriptPageViewModel {
    public var scriptTitle: String = ""
    public var currentPageNumber: Int = 1
    public var totalPages: Int = 1
    public var lines: [ScriptLine] = []

    public var onBack: (() -> Void)?

    public init() {
        loadMockData()
    }

    public func goToNextPage() {
        guard currentPageNumber < totalPages else { return }
        currentPageNumber += 1
        loadLinesForCurrentPage()
    }

    public func goToPreviousPage() {
        guard currentPageNumber > 1 else { return }
        currentPageNumber -= 1
        loadLinesForCurrentPage()
    }

    public func didTapBack() {
        onBack?()
    }

    private func loadMockData() {
        let script = scriptMock
        scriptTitle = script.title
        totalPages = script.pages.count
        loadLinesForCurrentPage()
    }

    private func loadLinesForCurrentPage() {
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
