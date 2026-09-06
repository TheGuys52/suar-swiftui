//
//  AIScriptParserService.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 02/09/26.
//

import Foundation

public final class AIScriptParserService: ScriptParserServiceProtocol {
    private let baseURL = "https://gateway.olagon.site/anthropic/v1/messages"
    private let apiKey: String
    private let chunkSize: Int

    public init(apiKey: String, chunkSize: Int = 4) {
        self.apiKey = apiKey
        self.chunkSize = chunkSize
    }

    public func parseScript(
        rawPagesText: [Int: String],
        scriptTitle: String,
        sourceFileName: String,
        onProgress: ((_ currentPage: Int, _ totalPages: Int) -> Void)? = nil
    ) async throws -> Script {
        let sortedPageNumbers = rawPagesText.keys.sorted()

        // Filter out pages that are truly empty (no content lines)
        // Note: cover pages with ~3 lines pass through — they'll get a title block added later
        let contentfulPages = sortedPageNumbers.filter { pageNum in
            guard let text = rawPagesText[pageNum], !text.isEmpty else { return false }
            let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            return lines.count >= 3
        }

        // Build chunks of [chunkSize] pages each
        let chunks = stride(from: 0, to: contentfulPages.count, by: chunkSize).map { startIndex in
            Array(contentfulPages[startIndex..<min(startIndex + chunkSize, contentfulPages.count)])
        }

        var allPages: [ScriptPage] = []
        var globalBlockOrder = 1
        var previousUnresolved: AIBlock?

        for (chunkIndex, pageNumbers) in chunks.enumerated() {
            let chunkStartPage = pageNumbers.first ?? 1
            let chunkEndPage = pageNumbers.last ?? chunkStartPage

            // Build chunk content with page markers
            var chunkContent = ""
            for pageNum in pageNumbers {
                chunkContent += "--- PAGE \(pageNum) ---\n"
                if let text = rawPagesText[pageNum], !text.isEmpty {
                    chunkContent += text + "\n"
                }
            }

            let result = try await parseChunk(
                content: chunkContent,
                previousUnresolved: previousUnresolved,
                chunkStartPage: chunkStartPage,
                chunkEndPage: chunkEndPage
            )

            // Merge confirmed continuation from previous unresolved block
            if let merged = result.mergedStartBlock {
                let block = makeScriptBlock(
                    from: merged,
                    orderIndex: globalBlockOrder,
                    startPage: chunkStartPage,
                    endPage: merged.isTrailingResolved == true ? chunkEndPage : nil
                )
                allPages.append(ScriptPage(
                    pageNumber: chunkStartPage,
                    rawExtractedText: "",
                    blocks: [block]
                ))
                globalBlockOrder += 1
            }

            // Add new blocks, grouped by their page
            for block in result.newBlocks {
                let blockStartPage = block.startPage ?? chunkStartPage
                let blockEndPage = block.endPage ?? chunkEndPage

                let scriptBlock = makeScriptBlock(
                    from: block,
                    orderIndex: globalBlockOrder,
                    startPage: blockStartPage,
                    endPage: blockEndPage
                )

                if let lastPage = allPages.last, lastPage.pageNumber == blockStartPage {
                    lastPage.blocks.append(scriptBlock)
                } else {
                    let scriptPage = ScriptPage(
                        pageNumber: blockStartPage,
                        rawExtractedText: "",
                        blocks: [scriptBlock]
                    )
                    allPages.append(scriptPage)
                }
                globalBlockOrder += 1
            }

            // Carry unresolved block forward
            previousUnresolved = result.trailingUnresolvedBlock

            // Flush remaining unresolved as final block
            if chunkIndex == chunks.count - 1, let unresolved = previousUnresolved {
                let block = makeScriptBlock(
                    from: unresolved,
                    orderIndex: globalBlockOrder,
                    startPage: chunkEndPage,
                    endPage: nil as Int?
                )
                if let lastPage = allPages.last, lastPage.pageNumber == chunkEndPage {
                    lastPage.blocks.append(block)
                } else {
                    allPages.append(ScriptPage(
                        pageNumber: chunkEndPage,
                        rawExtractedText: "",
                        blocks: [block]
                    ))
                }
            }

            // Report progress by actual last page in the current chunk
            let chunkStartIdx = chunkIndex * chunkSize
            let chunkEndIdx = min(chunkStartIdx + chunkSize, contentfulPages.count)
            let lastContentfulPage = contentfulPages[chunkEndIdx - 1]
            onProgress?(lastContentfulPage, contentfulPages.count)
        }

        // Fill in ALL original OCR pages that had no blocks returned by AI
        let processedPageNumbers = Set(allPages.map { $0.pageNumber })
        for missingPage in sortedPageNumbers.filter({ !processedPageNumbers.contains($0) }) {
            allPages.append(ScriptPage(
                pageNumber: missingPage,
                rawExtractedText: "",
                blocks: []
            ))
        }
        allPages.sort { $0.pageNumber < $1.pageNumber }

        // If page 1 has no blocks (e.g. cover page was filtered), add title as scene header
        if let firstPageNum = contentfulPages.first,
           let firstPage = allPages.first(where: { $0.pageNumber == firstPageNum }),
           firstPage.blocks.isEmpty {
            firstPage.blocks.append(ScriptBlock(
                orderIndex: 1,
                blockType: .sceneHeader,
                content: scriptTitle,
                startPageNumber: firstPageNum
            ))
            globalBlockOrder = 2
        }

        return Script(
            title: scriptTitle,
            lastReadPage: 1,
            pageCount: sortedPageNumbers.count,
            sourceFileName: sourceFileName,
            pages: allPages
        )
    }

    // MARK: - Chunk Parsing

    private struct ChunkParseResult {
        let mergedStartBlock: AIBlock?
        let newBlocks: [AIBlock]
        let trailingUnresolvedBlock: AIBlock?
    }

    private func parseChunk(
        content: String,
        previousUnresolved: AIBlock?,
        chunkStartPage: Int,
        chunkEndPage: Int
    ) async throws -> ChunkParseResult {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }

        let unresolvedContext: String
        if let prev = previousUnresolved {
            unresolvedContext = """

            --- CONTINUATION CONTEXT ---
            Block berikut terpotong di akhir chunk sebelumnya. Jika baris pertama teks baru adalah kelanjutan dari block ini, GABUNGKAN isinya dan kembalikan sebagai "mergedStartBlock". Jika bukan kelanjutan, kembalikan null untuk mergedStartBlock.
            Previous unresolved block:
              type: \(prev.type)
              characterName: \(prev.characterName ?? "null")
              content: \(prev.content ?? "")
            --- END CONTEXT ---
            """
        } else {
            unresolvedContext = ""
        }

        let systemPrompt = """
        Ubah teks skenario mentah hasil OCR berikut menjadi struktur JSON.
        Setiap blok harus memiliki field:
        - "type": salah satu dari ["sceneHeader", "dialogue", "stageDirection"]
        - "characterName": nama tokoh jika type adalah "dialogue", JANGAN hilangkan angka urut di depan nama (misal: "8. WANITA" tetap "8. WANITA", bukan "WANITA"). Jika bukan dialogue isi dengan null.
        - "cueDescription": petunjuk emosi/aksi dalam tanda kurung jika ada, jika tidak ada isi dengan null.
        - "content": isi teks atau dialog dari elemen tersebut.
        - "startPage": nomor halaman dimulainya block ini.
        - "endPage": nomor halaman berakhirnya block ini (isi jika block menyambung ke halaman berikutnya).
        - "isTrailingResolved": true jika block ini UTUH dan tidak terpotong di akhir chunk. false jika block terpotong/masih berlanjut.

        RETURNIKAN HANYA JSON object murni (tanpa markdown codeblock atau teks tambahan) dengan struktur:
        {
          "mergedStartBlock": <AIBlock> | null,
          "newBlocks": [<AIBlock>, ...],
          "trailingUnresolvedBlock": <AIBlock> | null
        }

        - "mergedStartBlock": Jika ada block pertama di chunk ini yang melanjutkan unresolved block dari chunk sebelumnya, ISI DENGAN block yang sudah di-GABUNGKAN (gabungkan content + isTrailingResolved=true). Jika TIDAK ada kelanjutan, NULL.
        - "newBlocks": Semua block baru yang UTUH dalam chunk ini (tidak termasuk mergedStartBlock). Setiap block harus memiliki startPage dan endPage yang valid.
        - "trailingUnresolvedBlock": Jika block TERAKHIR di chunk ini terpotong (isTrailingResolved=false), KEMBALIKAN block tersebut. Jika UTUH, NULL.

        ATURAN PENTING:
        - Marker "--- PAGE X ---" menunjukkan awal halaman baru.
        - Jika block terpotong di batas halaman (misal: dialogue dimulai di halaman 1 dan berlanjut di halaman 2), set isTrailingResolved=false pada block di halaman 1, dan block di halaman 2 menjadi kelanjutan (akan di-merge oleh chunk berikutnya).
        - Block dengan isTrailingResolved=false di akhir chunk harus dikembalikan sebagai trailingUnresolvedBlock.
        - JANGAN mengubah angka ordinal di depan nama karakter (misal: "8. WANITA").
        """

        let payload: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 100000,
            "system": systemPrompt + unresolvedContext,
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

        return try decodeChunkResponse(data: data)
    }

    private struct ChunkAIResponse: Decodable {
        let mergedStartBlock: AIBlock?
        let newBlocks: [AIBlock]?
        let trailingUnresolvedBlock: AIBlock?
    }

    private func decodeChunkResponse(data: Data) throws -> ChunkParseResult {
        struct AnthropicResponse: Decodable {
            struct Content: Decodable {
                let type: String
                let text: String?
            }
            let content: [Content]
        }

        let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)

        guard let textBlock = response.content.first(where: { $0.type == "text" }),
              let rawJsonString = textBlock.text else {
            throw URLError(.cannotParseResponse)
        }

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

        let chunkResponse = try JSONDecoder().decode(ChunkAIResponse.self, from: jsonData)
        return ChunkParseResult(
            mergedStartBlock: chunkResponse.mergedStartBlock,
            newBlocks: chunkResponse.newBlocks ?? [],
            trailingUnresolvedBlock: chunkResponse.trailingUnresolvedBlock
        )
    }

    // MARK: - Helpers

    private func makeScriptBlock(
        from block: AIBlock,
        orderIndex: Int,
        startPage: Int,
        endPage: Int?
    ) -> ScriptBlock {
        let blockType: ScriptBlockType = {
            switch block.type {
            case "sceneHeader": return .sceneHeader
            case "dialogue": return .dialogue
            default: return .stageDirection
            }
        }()

        return ScriptBlock(
            orderIndex: orderIndex,
            blockType: blockType,
            characterName: block.characterName,
            content: block.content ?? "",
            cueDescription: block.cueDescription,
            startPageNumber: block.startPage ?? startPage,
            endPageNumber: endPage ?? block.endPage
        )
    }
}

// MARK: - AI Block (internal, used for parsing)
private struct AIBlock: Decodable {
    let type: String
    let characterName: String?
    let cueDescription: String?
    let content: String?
    let startPage: Int?
    let endPage: Int?
    let isTrailingResolved: Bool?
}
