//
//  AIScriptParserService.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 02/09/26.
//
//

import Foundation

public final class AIScriptParserService: ScriptParserServiceProtocol {
    private let baseURL = "https://gateway.olagon.site/anthropic/v1/messages"
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func parseScript(
        rawPagesText: [Int: String],
        scriptTitle: String,
        sourceFileName: String,
        onProgress: ((_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> Script {
        var allPages: [ScriptPage] = []
        var globalBlockOrder = 1
        
        let sortedPageNumbers = rawPagesText.keys.sorted()
        let totalPages = sortedPageNumbers.count

        for (index, pageNum) in sortedPageNumbers.enumerated() {
            guard let pageContent = rawPagesText[pageNum], !pageContent.isEmpty else {
                onProgress?(index + 1, totalPages)
                continue
            }

            let (parsedBlocks, nextOrder) = try await parsePageContent(
                pageContent,
                startingOrder: globalBlockOrder
            )

            globalBlockOrder = nextOrder

            let scriptPage = ScriptPage(
                pageNumber: pageNum,
                blocks: parsedBlocks
            )
            allPages.append(scriptPage)

            // Callback progress per halaman
            onProgress?(index + 1, totalPages)
        }

        return Script(
            title: scriptTitle,
            lastReadPage: 1,
            pageCount: totalPages,
            sourceFileName: sourceFileName,
            pages: allPages
        )
    }

    private func parsePageContent(
        _ content: String,
        startingOrder: Int
    ) async throws -> ([ScriptBlock], Int) {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }

        let systemPrompt = """
        Ubah teks skenario mentah hasil OCR berikut menjadi struktur JSON array of objects.
        Setiap object harus memiliki field:
        - "type": salah satu dari ["sceneHeader", "dialogue", "stageDirection"]
        - "characterName": nama tokoh jika type adalah "dialogue", jika bukan dialog isi dengan null.
        - "cueDescription": petunjuk emosi/aksi dalam tanda kurung jika ada pada dialog, jika tidak ada isi dengan null.
        - "content": isi teks atau dialog dari elemen tersebut.

        Kembalikan HANYA JSON array murni tanpa format markdown codeblock atau teks tambahan.
        """

        let payload: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 100000,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": content]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 300

        let (data, response) = try await URLSession.shared.data(for: request)

        print("[AI-Parser] Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let aiBlocks = try decodeAIResponse(data: data)
        
        var scriptBlocks: [ScriptBlock] = []
        var currentOrder = startingOrder

        for block in aiBlocks {
            let blockType: ScriptBlockType = {
                switch block.type {
                case "sceneHeader": return .sceneHeader
                case "dialogue": return .dialogue
                default: return .stageDirection
                }
            }()

            let scriptBlock = ScriptBlock(
                orderIndex: currentOrder,
                blockType: blockType,
                characterName: block.characterName,
                content: block.content ?? "",
                cueDescription: block.cueDescription
            )
            scriptBlocks.append(scriptBlock)
            currentOrder += 1
        }

        return (scriptBlocks, currentOrder)
    }

    private func decodeAIResponse(data: Data) throws -> [AIBlock] {
        struct AnthropicResponse: Decodable {
            struct Content: Decodable {
                let type: String
                let text: String?
            }
            let content: [Content]
        }

        let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)

        // Find the "text" block (skip "thinking" blocks)
        guard let textBlock = response.content.first(where: { $0.type == "text" }),
              let rawJsonString = textBlock.text else {
            throw URLError(.cannotParseResponse)
        }

        // Strip markdown code fences: ```json ... ```
        var jsonString = rawJsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonString.hasPrefix("```json") {
            jsonString = String(jsonString.dropFirst(7))
        } else if jsonString.hasPrefix("```") {
            jsonString = String(jsonString.dropFirst(3))
        }
        if jsonString.hasSuffix("```") {
            jsonString = String(jsonString.dropLast(3))
        }
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }

        return try JSONDecoder().decode([AIBlock].self, from: jsonData)
    }
}

private struct AIBlock: Decodable {
    let type: String
    let characterName: String?
    let cueDescription: String?
    let content: String?
}
