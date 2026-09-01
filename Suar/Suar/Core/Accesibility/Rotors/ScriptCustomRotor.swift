//
//  ScriptCustomRotor.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import SwiftData
import SwiftUI

public enum ScriptRotorType: String, CaseIterable, Identifiable {
    case scenes = "Adegan"
    case characters = "Tokoh"
    case cues = "Petunjuk Aksi"

    public var id: String { rawValue }
}

public struct ScriptRotorEntries {
    public let scenes: [ScriptBlock]
    public let characters: [ScriptBlock]

    public init(scenes: [ScriptBlock] = [], characters: [ScriptBlock] = []) {
        self.scenes = scenes
        self.characters = characters
    }

    public static func from(blocks: [ScriptBlock]) -> ScriptRotorEntries {
        let scenes = blocks.filter { $0.blockType == .sceneHeader }
        let seen = Set<String>()
        var characters: [ScriptBlock] = []
        for block in blocks {
            guard block.blockType == .characterName,
                  let name = block.characterName,
                  !name.isEmpty,
                  !seen.contains(name) else { continue }
            characters.append(block)
        }
        return ScriptRotorEntries(scenes: scenes, characters: characters)
    }
}

public struct ScriptCustomRotor<Content: View>: View {
    @Bindable var viewModel: ScriptPageViewModel
    @ViewBuilder let content: () -> Content

    public init(
        viewModel: ScriptPageViewModel,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._viewModel = Bindable(viewModel)
        self.content = content
    }

    public var body: some View {
        let entries = ScriptRotorEntries.from(blocks: viewModel.blocks)

        content()
            .accessibilityRotor(ScriptRotorType.scenes.rawValue, entries: {
                ForEach(entries.scenes) { block in
                    AccessibilityRotorEntry(block.content, id: block.id)
                }
            })
            .accessibilityRotor(ScriptRotorType.characters.rawValue, entries: {
                ForEach(entries.characters) { block in
                    AccessibilityRotorEntry(block.characterName ?? "", id: block.id)
                }
            })
    }
}
