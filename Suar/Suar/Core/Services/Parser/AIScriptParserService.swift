//
//  AIScriptParserService.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 02/09/26.
//

import Foundation

public enum AIScriptParserError: Error {
    case malformedResponse(String)
}

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

            let result = try await parseChunkWithRetry(
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

    private let maxRetries = 2

    private func parseChunkWithRetry(
        content: String,
        previousUnresolved: AIBlock?,
        chunkStartPage: Int,
        chunkEndPage: Int
    ) async throws -> ChunkParseResult {
        var lastError: Error?
        for attempt in 0..<(maxRetries + 1) {
            do {
                let result = try await parseChunk(
                    content: content,
                    previousUnresolved: previousUnresolved,
                    chunkStartPage: chunkStartPage,
                    chunkEndPage: chunkEndPage
                )
                if result.newBlocks.isEmpty {
                    print("[AI-Parser] Chunk \(chunkStartPage)-\(chunkEndPage): empty blocks, retry \(attempt + 1)/\(maxRetries + 1)")
                    throw AIScriptParserError.malformedResponse("Empty newBlocks")
                }
                return result
            } catch {
                lastError = error
                if attempt < maxRetries {
                    print("[AI-Parser] Chunk \(chunkStartPage)-\(chunkEndPage): error, retry \(attempt + 1)/\(maxRetries + 1)")
                }
            }
        }
        throw lastError ?? AIScriptParserError.malformedResponse("Unknown error after \(maxRetries) retries")
    }

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
            Block berikut terpotong di akhir chunk sebelumnya.
            Jika baris pertama teks baru adalah kelanjutan dari block ini,
            GABUNGKAN isinya dan kembalikan sebagai "mergedStartBlock".
            Jika bukan kelanjutan, kembalikan null untuk mergedStartBlock.
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
Kamu adalah parser skenario drama. Ubah teks hasil OCR menjadi JSON.

FORMAT INPUT:
- Teks berada di antara marker "--- PAGE X ---" yang menunjukkan nomor halaman.
- Dialog tokoh ditandai dengan format: "NAMA : isi" di mana NAMA diikuti titik dua.
  Contoh: "Bas : Isi dialog", "Frank : Isi dialog", "1. PRIA : Isi dialog", "Wanita : Isi dialog"
  NAMA adalah case-insensitive: "Bas", "Frank", "1. PRIA", "WANITA" semua valid.
- Jika setelah ":" kosong, dialogue content = baris-baris berikutnya (indent atau lanjutan) sampai tokoh berikutnya.
- TEKS TANPA "NAMA :" = stageDirection (bukan dialogue). Contoh: judul puisi, narasi, puisi tanpa tokoh.
- Baris yang hanya berisi karakter "=" atau "*" (atau keduanya) = transition block.

FORMAT OUTPUT (HANYA JSON, tanpa markdown):
{
  "mergedStartBlock": <AIBlock> | null,
  "newBlocks": [<AIBlock>, ...],
  "trailingUnresolvedBlock": <AIBlock> | null
}

ATURAN (PENTING):
1. SUATU BARIS = satu block. Tidak boleh gabung 2 baris berbeda jadi 1 block.
2. BARIS DENGAN "NAMA :" = dialogue block. characterName=NAMA (isi sebelum ":"), content=isi setelah ":".
   Jika setelah ":" kosong, AMBIL baris-baris berikutnya sebagai content.
   STOP collect jika baris berikutnya memiliki "NAMA :" baru (tokoh berbeda) atau scene header.
3. BARIS TANPA "NAMA :" (tidak ada titik dua setelah nama tokoh) = stageDirection.
   Contoh: judul puisi, narasi tanpa tokoh, block parenthetical (Suara, etc.).
4. Baris yang hanya berisi "=" atau "*" (contoh: "==================" atau "***** =============") = transition block.
5. "Bagian Pertama/Kedua/Ketiga", "***", atau "Dramatis Personae" = sceneHeader.
6. "(Suara: ...)" atau "(Suara...)" = stageDirection.
   "(tersenyum)", "(mengangguk)" dalam dialogue = cueDescription.
7. isTrailingResolved=true jika block UTUH, false jika terpotong.
8. Jangan kosongkan field content.

CONTOH 1 - Naskah dengan multi-line dialogue (ordinal + continue):
Input:
--- PAGE 2 ---
1. PRIA
(mengelus dada)
Ya Tuhan. Oh ya Tuhaan.
Tuhan atas
segala duka. Tuhan atas
semua jenis rasa sakit.
1. PRIA
(menundukkan kepala)
Tuhanku, Tuhanku...

Output:
{
  "mergedStartBlock": null,
  "newBlocks": [
    {
      "type": "dialogue",
      "characterName": "1. PRIA",
      "cueDescription": "mengelus dada",
      "content": "Ya Tuhan. Oh ya Tuhaan. Tuhan atas segala duka. Tuhan atas semua jenis rasa sakit.",
      "startPage": 2,
      "endPage": null,
      "isTrailingResolved": true
    },
    {
      "type": "dialogue",
      "characterName": "1. PRIA",
      "cueDescription": "menundukkan kepala",
      "content": "Tuhanku, Tuhanku...",
      "startPage": 2,
      "endPage": null,
      "isTrailingResolved": true
    }
  ],
  "trailingUnresolvedBlock": null
}

CONTOH 2 - Naskah dengan judul dan puisi:
Input:
--- PAGE 4 ---
Cintaku Padamu seperti Sudut Lingkaran
Bob : Berkali aku melukismu hanya gerimis yang tergores!
Bas : Malam ini tak ada yang kubawa lari selain ingatan dan pagi berapi!
============================
Frank : Tidurlah, sebelum semuanya bicara masa lalu dan hantu-hantu gentayangan.

Output:
{
  "mergedStartBlock": null,
  "newBlocks": [
    {
      "type": "stageDirection",
      "characterName": null,
      "cueDescription": null,
      "content": "Cintaku Padamu seperti Sudut Lingkaran",
      "startPage": 4,
      "endPage": null,
      "isTrailingResolved": true
    },
    {
      "type": "dialogue",
      "characterName": "Bob",
      "cueDescription": null,
      "content": "Berkali aku melukismu hanya gerimis yang tergores!",
      "startPage": 4,
      "endPage": null,
      "isTrailingResolved": true
    },
    {
      "type": "dialogue",
      "characterName": "Bas",
      "cueDescription": null,
      "content": "Malam ini tak ada yang kubawa lari selain ingatan dan pagi berapi!",
      "startPage": 4,
      "endPage": null,
      "isTrailingResolved": true
    },
    {
      "type": "transition",
      "characterName": null,
      "cueDescription": null,
      "content": "============================",
      "startPage": 4,
      "endPage": null,
      "isTrailingResolved": true
    },
    {
      "type": "dialogue",
      "characterName": "Frank",
      "cueDescription": null,
      "content": "Tidurlah, sebelum semuanya bicara masa lalu dan hantu-hantu gentayangan.",
      "startPage": 4,
      "endPage": null,
      "isTrailingResolved": true
    }
  ],
  "trailingUnresolvedBlock": null
}

CONTOH 2 - Halaman cover dan dialog:
Input:
--- PAGE 1 ---
Bangun Pagi Bahagia
Andy Sri Wahyudi
--- PAGE 2 ---
********************* =============== *********************
Bas : 1997, itu tadi adalah kegiatan masa remaja kami.
Frank : Frank
(Suara: suara gonggong anjing)
Ibu : Basss...!!

Output:
{
  "mergedStartBlock": null,
  "newBlocks": [
    {
      "type": "stageDirection",
      "characterName": null,
      "cueDescription": null,
      "content": "********************* =============== *********************",
      "startPage": 1,
      "endPage": null,
      "isTrailingResolved": true
    },
    {
      "type": "transition",
      "characterName": null,
      "cueDescription": null,
      "content": "====================",
      "startPage": 1,
      "endPage": null,
      "isTrailingResolved": true
    },
    {
      "type": "dialogue",
      "characterName": "Bas",
      "cueDescription": null,
      "content": "1997, itu tadi adalah kegiatan masa remaja kami.",
      "startPage": 2,
      "endPage": null,
      "isTrailingResolved": true
    },
    {
      "type": "dialogue",
      "characterName": "Bas",
      "cueDescription": null,
      "content": "1997, itu tadi adalah kegiatan masa remaja kami.",
      "startPage": 2,
      "endPage": null,
      "isTrailingResolved": true
    },
    {
      "type": "dialogue",
      "characterName": "Frank",
      "cueDescription": null,
      "content": "Frank",
      "startPage": 2,
      "endPage": null,
      "isTrailingResolved": true
    },
    {
      "type": "dialogue",
      "characterName": "Ibu",
      "cueDescription": null,
      "content": "Bangun! Kau mau sampai kapan berbaring di sini?",
      "startPage": 2,
      "endPage": null,
      "isTrailingResolved": true
    },
    {
      "type": "dialogue",
      "characterName": "Ibu",
      "cueDescription": null,
      "content": "Basss...!!",
      "startPage": 2,
      "endPage": null,
      "isTrailingResolved": true
    }
  ],
  "trailingUnresolvedBlock": null
}

JANGAN tambahkan teks di luar JSON.
"""

        let payload: [String: Any] = [
            "model": "claude-opus-4-6",
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
            case "transition": return .transition
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
