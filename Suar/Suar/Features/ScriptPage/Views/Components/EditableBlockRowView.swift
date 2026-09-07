//
//  EditableBlockRowView.swift
//  Suar
//
//  Created by Adiat Rahman on 06/09/26.
//

import SwiftUI

struct EditableBlockRowView: View {
    let block: ScriptBlock
    let onSave: (String) async -> Void
    
    @State private var editedContent: String = ""
    
    var body: some View {
        Group {
            switch block.blockType {
            case .sceneHeader:
                sceneHeaderRow
            case .characterName:
                characterRow
            case .dialogue:
                dialogueRow
            case .stageDirection:
                stageDirectionRow
            default:
                Text(block.content)
                    .font(Font.custom("Courier", size: 18))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            editedContent = block.content
        }
        .onChange(of: block.content) { _, newValue in
            editedContent = newValue
        }
    }
    
    // MARK: - Scene Header
    
    private var sceneHeaderRow: some View {
        TextField("Ketik...", text: $editedContent, axis: .vertical)
            .font(.headline.bold())
            .foregroundStyle(Color.themeRed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
            .onChange(of: editedContent) { _, newValue in
                if newValue != block.content {
                    Task {
                        await onSave(newValue)
                    }
                }
            }
    }
    
    // MARK: - Character
    
    private var characterRow: some View {
        TextField("Ketik...", text: $editedContent, axis: .vertical)
            .font(.subheadline.bold())
            .foregroundStyle(Color.themeRed)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 6)
            .textInputAutocapitalization(.characters)
            .onChange(of: editedContent) { _, newValue in
                if newValue != block.content {
                    Task {
                        await onSave(newValue)
                    }
                }
            }
    }
    
    // MARK: - Dialogue
    
    private var dialogueRow: some View {
        VStack(alignment: .center, spacing: 4) {
            if let characterName = block.characterName {
                Text(characterName)
                    .font(Font.custom("Courier", size: 20))
                    .foregroundStyle(.primary)
                    .bold()
            }
            
            if let cue = block.cueDescription {
                Text(cue)
                    .font(Font.custom("Courier", size: 15))
                    .foregroundStyle(.secondary)
            }
            
            TextField("Ketik...", text: $editedContent, axis: .vertical)
                .font(Font.custom("Courier", size: 18))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .onChange(of: editedContent) { _, newValue in
                    if newValue != block.content {
                        Task {
                            await onSave(newValue)
                        }
                    }
                }
        }
        .frame(maxWidth: 280, alignment: .center)
    }
    
    // MARK: - Stage Direction
    
    private var stageDirectionRow: some View {
        TextField("Ketik...", text: $editedContent, axis: .vertical)
            .font(Font.custom("Courier", size: 18))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: editedContent) { _, newValue in
                if newValue != block.content {
                    Task {
                        await onSave(newValue)
                    }
                }
            }
    }
}
