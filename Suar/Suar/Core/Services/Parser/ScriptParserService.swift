//
//  ScriptParserService.swift
//  Suar
//
//  Created by Adiat Rahman on 28/08/26.
//

import Foundation

public struct ScriptParserService: ScriptParserServiceProtocol {
    public init() {}
    
    public func parseScript(
        rawPagesText: [Int: String],
        scriptTitle: String,
        sourceFileName: String
    ) async throws -> Script {
        // Buat object script kosong
        let script = Script(title: scriptTitle, sourceFileName: sourceFileName)
        
        // Global counter untuk orderIndex
        var globalOrderIndex = 0
        
        // Iterasi setiap halaman urut
        for pageNumber in rawPagesText.keys.sorted() {
            guard let rawText = rawPagesText[pageNumber] else {
                continue
            }
            
            // Buat ScriptPage untuk halaman ini
            let page = ScriptPage(pageNumber: pageNumber, rawExtractedText: rawText, script: script)
            
            // Pecah teks jadi baris (newline)
            let lines = rawText.components(separatedBy: "\n")
            
            // Klasifikasi character name per baris
            var previousWasCharacterName = false
            
            var hasSeenCharacterNameInSplit = false
            
            var narrationBuffer = ""
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                
                if trimmed.isEmpty {
                    // Flush narration buffer
                    if !narrationBuffer.isEmpty {
                        let merged = narrationBuffer.trimmingCharacters(in: .whitespaces)
                        let block = ScriptBlock(
                            orderIndex: globalOrderIndex,
                            blockType: .narration,
                            content: merged,
                            page: page
                        )
                        page.blocks.append(block)
                        globalOrderIndex += 1
                        narrationBuffer = ""
                    }
                    previousWasCharacterName = false
                    continue
                }
                
                // Coba pecah line (characterName + stageDirection + dialogue)
                let splitBlocks = splitMixedLine(trimmed)
                
                if splitBlocks.count > 1 {
                    // Line mengandung multiple types — flush buffer narration dulu
                    if !narrationBuffer.isEmpty {
                        let merged = narrationBuffer.trimmingCharacters(in: .whitespaces)
                        let block = ScriptBlock(
                            orderIndex: globalOrderIndex,
                            blockType: .narration,
                            content: merged,
                            page: page
                        )
                        page.blocks.append(block)
                        globalOrderIndex += 1
                        narrationBuffer = ""
                    }
                    
                    // Process setiap block hasil split (tidak buffering)
                    for (blockType, content, _) in splitBlocks {
                        var finalType = blockType

                        // Override: narration + ada characterName sebelumnya di split ini
                        if finalType == .narration && hasSeenCharacterNameInSplit {
                            finalType = .dialogue
                        }

                        let block = ScriptBlock(
                            orderIndex: globalOrderIndex,
                            blockType: finalType,
                            content: content,
                            page: page
                        )

                        if finalType == .characterName {
                            let name = content.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
                            block.characterName = name
                            hasSeenCharacterNameInSplit = true
                            previousWasCharacterName = true
                        } else {
                            previousWasCharacterName = false
                        }

                        page.blocks.append(block)
                        globalOrderIndex += 1
                    }
                    
                } else {
                    // Line tunggal — pakai classify normal + narration buffering
                    var blockType = classify(line: trimmed)
                    
                    if blockType == .narration && previousWasCharacterName {
                        blockType = .dialogue
                    }
                    
                    if blockType == .narration {
                        narrationBuffer += trimmed + " "
                    } else {
                        // Flush buffer narration
                        if !narrationBuffer.isEmpty {
                            let merged = narrationBuffer.trimmingCharacters(in: .whitespaces)
                            let block = ScriptBlock(
                                orderIndex: globalOrderIndex,
                                blockType: .narration,
                                content: merged,
                                page: page
                            )
                            page.blocks.append(block)
                            globalOrderIndex += 1
                            narrationBuffer = ""
                        }
                        
                        let block = ScriptBlock(
                            orderIndex: globalOrderIndex,
                            blockType: blockType,
                            content: trimmed,
                            page: page
                        )
                        
                        if blockType == .characterName {
                            var name = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
                            block.characterName = name
                            previousWasCharacterName = true
                        } else {
                            previousWasCharacterName = false
                        }
                        
                        page.blocks.append(block)
                        globalOrderIndex += 1
                    }
                }
            }
            
            // Tambah halaman ke script
            script.pages.append(page)
        }
        
        // Update pageCount di script
        script.pageCount = script.pages.count
        
        return script
    }
    
    // MARK: - Regex Patterns
    
    private let sceneHeaderPattern: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: "^(ACT|SCENE|BAB|EPISODE|PROLOGUE|EPILOGUE)\\s+[IVXLCDM0-9A-Za-z]+",
            options: []
        )
    }()
    
    private let stageDirectionPattern: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: "^\\s*(\\(|\\[).*(\\)|\\])\\s*$",
            options: []
        )
    }()
    
    // MARK: - Implement Classify
    
    private func classify(line: String) -> ScriptBlockType {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Cek Stage Dircetion
        if isStageDirection(trimmed) {
            return .stageDirection
        }
        
        // Cek Scene Header
        if isSceneHeader(trimmed) {
            return .sceneHeader
        }
        
        // Cek character name (ada colon di akhir)
        if isCharacterName(trimmed) {
            return .characterName
        }
        
        return .narration
    }
    
    private func isStageDirection(_ line: String) -> Bool {
        guard let regex = stageDirectionPattern else { return false }
        let range = NSRange(line.startIndex..., in: line)
        return regex.firstMatch(in: line, options: [], range: range)  != nil
    }
    
    private func isSceneHeader(_ line: String) -> Bool {
        guard let regex = sceneHeaderPattern else { return false }
        let range = NSRange(line.startIndex..., in: line)
        return regex.firstMatch(in: line, options: [], range: range) != nil
    }
    
    private func isCharacterName(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Cek ada colon
        guard let colonIndex = trimmed.firstIndex(of: ":") else { return false }
        
        // Ambil bagian sebelum colon
        let namePart = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
        
        // Too long = narasi/deskripsi
        if namePart.count > 30 { return false }
        
        // Too many words = narasi
        let words = namePart.split(separator: " ")
        if words.count > 4 { return false }
        
        // All lowercase = narasi section header
        if namePart.filter({ $0.isLetter }).allSatisfy({ $0.isLowercase }) {
            return false
        }
        
        // Allow single word ALL CAPS (contoh "JOHN:", "PRIA:")
        if words.count == 1 {
            return namePart.filter({ $0.isLetter }).allSatisfy({ $0.isUppercase })
        }
        
        // Has lowercase letters = narasi (character name usually all caps)
        if namePart.contains(where: { $0.isLowercase }) {
            return false
        }
        
        return true
    }
    
    // MARK: - Line Splitting
    
    func splitMixedLine(_ line: String) -> [(blockType: ScriptBlockType, content: String, isAfterCharacterName: Bool)] {
        var result: [(ScriptBlockType, String, Bool)] = []
        var remaining = line.trimmingCharacters(in: .whitespaces)
        
        while !remaining.isEmpty {
            // Cek stage direction
            if remaining.hasPrefix("(") || remaining.hasPrefix("[") {
                if let openIdx = remaining.firstIndex(where: { $0 == "(" || $0 == "[" }),
                   let closeIdx = remaining.firstIndex(where: { $0 == ")" || $0 == "]" }),
                   closeIdx > openIdx {
                    let stageStart = remaining.index(after: openIdx)
                    let stageContent = String(remaining[stageStart..<closeIdx])
                    if !stageContent.trimmingCharacters(in: .whitespaces).isEmpty {
                        result.append((.stageDirection, "(" + stageContent + ")", false))
                    }
                    remaining = String(remaining[remaining.index(after: closeIdx)...]).trimmingCharacters(in: .whitespaces)
                    continue
                }
            }
            
            // Cek character name
            if let colonIdx = remaining.firstIndex(of: ":") {
                let namePart = String(remaining[..<colonIdx]).trimmingCharacters(in: .whitespaces)
                if isCharacterName(namePart + ":") {
                    var name = namePart
                    let numberPattern = "^[0-9]+\\.\\s*"
                    if let regex = try? NSRegularExpression(pattern: numberPattern) {
                        let range = NSRange(name.startIndex..., in: name)
                        name = regex.stringByReplacingMatches(in: name, range: range, withTemplate: "")
                    }
                    result.append((.characterName, name.trimmingCharacters(in: .whitespaces) + ":", true))
                    remaining = String(remaining[remaining.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                    continue
                }
            }
            
            // Sisanya
            if !remaining.isEmpty {
                result.append((.narration, remaining, false))
                remaining = ""
            }
        }
        
        return result
    }
}
