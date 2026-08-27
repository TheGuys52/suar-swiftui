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
        
        // Urutkan nomor halaman agar pemrosesan berurutan
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
            pages: allPages,
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
        let cleanedLines = filterNoise(from: rawLines)
        
        var lineIndex = 0
        while lineIndex < cleanedLines.count {
            let line = cleanedLines[lineIndex].trimmingCharacters(in: .whitespaces)
            
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
            
            // 2. Deteksi Tokoh dan Dialog (Contoh: "1. PRIA :" atau "PRIA :")
            if let (character, initialDialogue) = matchCharacterAndDialogue(line) {
                var fullDialogue = initialDialogue
                
                lineIndex += 1
                while lineIndex < cleanedLines.count {
                    let nextLine = cleanedLines[lineIndex].trimmingCharacters(in: .whitespaces)
                    if nextLine.isEmpty || isSceneHeader(nextLine) || matchCharacterAndDialogue(nextLine) != nil || isStageDirection(nextLine) {
                        break
                    }
                    fullDialogue += "\n" + nextLine
                    lineIndex += 1
                }
                
                // Ekstraksi instruksi dalam kurung "(mengelus dada)"
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
            
            // 3. Deteksi Petunjuk Panggung / Narasi (ALL CAPS Paragraf)
            if isStageDirection(line) {
                var fullStageDirection = line
                lineIndex += 1
                while lineIndex < cleanedLines.count {
                    let nextLine = cleanedLines[lineIndex].trimmingCharacters(in: .whitespaces)
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
            
            // Fallback untuk narasi umum
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
    
    // MARK: - Pattern Matching Rules
    private func filterNoise(from lines: [String]) -> [String] {
        lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return false }
            
            // Membuang footer seperti "Lakon Ruang Tunggu | 1" atau "Lakon Ruang Tunggu 1"
            let pattern = "Lakon Ruang Tunggu.*\\d+$"
            let range = NSRange(location: 0, length: trimmed.utf16.count)
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                return false
            }
            return true
        }
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
            let character = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
            let dialogue = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
            return (character, dialogue)
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
