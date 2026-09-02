//
//  ScriptParserService.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 27/08/26.
//

import Foundation

public final class ScriptParserService: ScriptParserServiceProtocol {
    
    public init() {}
    
    public func parseScript(
        rawPagesText: [Int: String],
        scriptTitle: String,
        sourceFileName: String
    ) async throws -> Script {
        var allPages: [ScriptPage] = []
        var globalBlockOrder = 1
        
        let sortedPageNumbers = rawPagesText.keys.sorted()
        
        for pageNum in sortedPageNumbers {
            guard let pageContent = rawPagesText[pageNum] else { continue }
            
            let (parsedBlocks, nextOrder) = parsePageContent(
                pageContent,
                pageNumber: pageNum,
                startingOrder: globalBlockOrder
            )
            
            globalBlockOrder = nextOrder
            
            let scriptPage = ScriptPage(
                pageNumber: pageNum,
                blocks: parsedBlocks
            )
            allPages.append(scriptPage)
        }
        
        return Script(
            title: scriptTitle,
            lastReadPage: 1,
            pageCount: sortedPageNumbers.count,
            sourceFileName: sourceFileName,
            pages: allPages
        )
    }
    
    // MARK: - Core Parser State Machine
    private func parsePageContent(
        _ content: String,
        pageNumber: Int,
        startingOrder: Int
    ) -> ([ScriptBlock], Int) {
        var blocks: [ScriptBlock] = []
        var currentOrder = startingOrder
        
        let rawLines = content.components(separatedBy: .newlines)
        let normalizedLines = normalizeAndMergeLines(rawLines)
        
        var lineIndex = 0
        while lineIndex < normalizedLines.count {
            let line = normalizedLines[lineIndex].trimmingCharacters(in: .whitespaces)
            
            if line.isEmpty {
                lineIndex += 1
                continue
            }
            
            // 1. Deteksi Header Babak / Judul Bagian
            if isSceneHeader(line) {
                let block = ScriptBlock(
                    orderIndex: currentOrder,
                    blockType: .sceneHeader,
                    content: line
                )
                blocks.append(block)
                currentOrder += 1
                lineIndex += 1
                continue
            }
            
            // 2. Deteksi Tokoh dan Dialog
            if let (character, initialDialogue) = matchCharacterAndDialogue(line) {
                var fullDialogue = initialDialogue
                
                lineIndex += 1
                while lineIndex < normalizedLines.count {
                    let nextLine = normalizedLines[lineIndex].trimmingCharacters(in: .whitespaces)
                    if nextLine.isEmpty || isSceneHeader(nextLine) || matchCharacterAndDialogue(nextLine) != nil || isStageDirection(nextLine) {
                        break
                    }
                    fullDialogue += "\n" + nextLine
                    lineIndex += 1
                }
                
                let (cueText, cleanDialogueText) = extractCue(from: fullDialogue)
                
                let block = ScriptBlock(
                    orderIndex: currentOrder,
                    blockType: .dialogue,
                    characterName: character,
                    content: cleanDialogueText,
                    cueDescription: cueText
                )
                blocks.append(block)
                currentOrder += 1
                continue
            }
            
            // 3. Deteksi Petunjuk Panggung / Narasi
            if isStageDirection(line) {
                var fullStageDirection = line
                lineIndex += 1
                while lineIndex < normalizedLines.count {
                    let nextLine = normalizedLines[lineIndex].trimmingCharacters(in: .whitespaces)
                    if nextLine.isEmpty || isSceneHeader(nextLine) || matchCharacterAndDialogue(nextLine) != nil {
                        break
                    }
                    fullStageDirection += " " + nextLine
                    lineIndex += 1
                }
                
                let block = ScriptBlock(
                    orderIndex: currentOrder,
                    blockType: .stageDirection,
                    content: fullStageDirection
                )
                blocks.append(block)
                currentOrder += 1
                continue
            }
            
            // Fallback Narasi
            let block = ScriptBlock(
                orderIndex: currentOrder,
                blockType: .stageDirection,
                content: line
            )
            blocks.append(block)
            currentOrder += 1
            lineIndex += 1
        }
        
        return (blocks, currentOrder)
    }
    
    // MARK: - Normalization & Line Merging
    private func normalizeAndMergeLines(_ rawLines: [String]) -> [String] {
        var cleaned: [String] = []
        
        // Step A: Cleaning noise & pipe symbols
        for line in rawLines {
            var trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Clean table/PDF vertical bars
            if trimmed.hasPrefix("|") {
                trimmed = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
            }
            if trimmed.contains("| :") {
                trimmed = trimmed.replacingOccurrences(of: "| :", with: ":")
            }
            
            // Filter noise header/footer
            let noisePattern = "Lakon Ruang Tunggu.*"
            let range = NSRange(location: 0, length: trimmed.utf16.count)
            if let regex = try? NSRegularExpression(pattern: noisePattern, options: .caseInsensitive),
               regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                continue
            }
            
            if !trimmed.isEmpty {
                cleaned.append(trimmed)
            }
        }
        
        // Step B: Merge split dialogue and two-column character/dialogue pairs
        var result: [String] = []
        var characterQueue: [String] = []

        for line in cleaned {
            if line.hasPrefix(":") {
                if !characterQueue.isEmpty {
                    let charName = characterQueue.removeFirst()
                    result.append("\(charName) \(line)")
                } else {
                    result.append(line)
                }
            } else if isStandaloneCharacterName(line) {
                characterQueue.append(line)
            } else {
                // Non-character content: flush queued character names and pair
                // the most recent one with this line (two-column layout: char on left,
                // dialogue on right, read as separate lines after Y-X sort).
                while !characterQueue.isEmpty {
                    result.append(characterQueue.removeFirst())
                }
                // If the previous result was a dialogue line (ends without :), merge
                // this line as continuation.
                result.append(line)
            }
        }

        while !characterQueue.isEmpty {
            result.append(characterQueue.removeFirst())
        }

        // Step C: Two-column post-pass — pair orphaned character names with following
        // dialogue lines that don't already have a colon. E.g.:
        //   ["44. PRIA", "(berusaha...)", "Ayo, ikut aku berdoa."]
        // becomes:
        //   ["44. PRIA : (berusaha...)", "44. PRIA : Ayo, ikut aku berdoa."]
        var postResult: [String] = []
        var i = 0
        while i < result.count {
            let line = result[i]
            if isStandaloneCharacterName(line) {
                // Look ahead for the next non-character-name line to pair with.
                var merged = false
                for j in (i + 1)..<result.count {
                    let nextLine = result[j]
                    if isStandaloneCharacterName(nextLine) {
                        break // Stop at next character — don't steal its dialogue
                    }
                    // Don't merge if next line is already a complete dialogue entry.
                    if matchCharacterAndDialogue(nextLine) != nil {
                        break
                    }   
                    // Merge character name with the first non-character line we find.
                    postResult.append("\(line) : \(nextLine)")
                    result[j] = "" // mark as consumed
                    merged = true
                    break
                }
                if !merged {
                    postResult.append(line)
                }
            } else {
                postResult.append(line)
            }
            i += 1
        }

        return postResult.filter { !$0.isEmpty }
    }
    
    private func isStandaloneCharacterName(_ line: String) -> Bool {
        let pattern = "^(?:\\d+\\.\\s*)?([A-Z0-9\\s\\&\\-]+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return false }
        let range = NSRange(location: 0, length: line.utf16.count)
        
        if regex.firstMatch(in: line, options: [], range: range) != nil {
            let cleanName = line.replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
            return cleanName.count <= 25 && cleanName.components(separatedBy: .whitespaces).count <= 4
        }
        return false
    }
    
    private func isSceneHeader(_ line: String) -> Bool {
        let headers = ["Bagian Pertama", "Bagian Kedua", "Bagian Ketiga", "Bagian Keempat", "Dramatis Personae:", "***"]
        return headers.contains { line.localizedCaseInsensitiveContains($0) }
    }
    
    private func matchCharacterAndDialogue(_ line: String) -> (String, String)? {
        let pattern = "^(?:\\d+\\.\\s*)?([A-Z0-9\\s\\&\\-]+)\\s*:\\s*(.*)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        
        let nsString = line as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        if let match = regex.firstMatch(in: line, options: [], range: range) {
            var character = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
            let dialogue = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
            
            // Normalisasi nama tokoh (contoh: "1. PRIA" -> "PRIA")
            character = character.replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
            
            // Validasi: Panjang nama tokoh maks 25 karakter & maks 4 kata (mencegah narasi ALL CAPS terdeteksi tokoh)
            if character.count <= 25 && character.components(separatedBy: .whitespaces).count <= 4 {
                return (character, dialogue)
            }
        }
        
        return nil
    }
    
    private func extractCue(from text: String) -> (String?, String) {
        let pattern = "^\\s*\\(([^)]+)\\)\\s*(.*)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return (nil, text)
        }
        
        let nsString = text as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            let cue = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
            let remainingDialogue = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
            return (cue.isEmpty ? nil : cue, remainingDialogue)
        }
        
        return (nil, text)
    }
    
    private func isStageDirection(_ line: String) -> Bool {
        let lettersOnly = line.components(separatedBy: CharacterSet.letters.inverted).joined()
        guard !lettersOnly.isEmpty else { return false }
        
        let uppercaseLetters = lettersOnly.filter { $0.isUppercase }
        let uppercaseRatio = Double(uppercaseLetters.count) / Double(lettersOnly.count)
        
        return uppercaseRatio >= 0.8
    }
}
