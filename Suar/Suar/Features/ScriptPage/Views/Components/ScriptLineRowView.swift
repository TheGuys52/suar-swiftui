import SwiftUI

struct ScriptLineRowView: View {
    let block: ScriptBlock

    var body: some View {
        switch block.blockType {
        case .sceneHeader:
            sceneHeaderRow
        case .characterName:
            characterRow
        case .dialogue:
            dialogueRow
        case .stageDirection:
            stageDirectionRow
        case .parenthetical:
            parentheticalRow
        case .transition:
            transitionRow
        }
    }

    // MARK: - Scene Header

    private var sceneHeaderRow: some View {
        Text(block.content)
            .font(.headline)
            .bold()
            .foregroundStyle(Color.themeRed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Adegan. \(block.content)")
    }

    // MARK: - Character

    private var characterRow: some View {
        Text(block.content.uppercased())
            .font(.subheadline)
            .bold()
            .foregroundStyle(Color.themeRed)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 6)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Tokoh. \(block.content)")
    }

    // MARK: - Dialogue

    private var dialogueRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let characterName = block.characterName {
                Text(characterName.uppercased())
                    .font(.headline)
                    .foregroundStyle(Color.themeRed)
            }

            Text(block.content)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: 280, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelForDialogue)
    }

    private var accessibilityLabelForDialogue: String {
        var label = block.characterName ?? ""
        if let cue = block.cueDescription {
            label += ", \(cue)"
        }
        label += ". \(block.content)"
        return label
    }

    // MARK: - Parenthetical

    private var parentheticalRow: some View {
        Text(block.content)
            .font(.caption)
            .italic()
            .foregroundStyle(.secondary)
            .frame(maxWidth: 280, alignment: .center)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Keterangan. \(block.content)")
    }

    // MARK: - Stage Direction

    private var stageDirectionRow: some View {
        Text(block.content)
            .font(.body)
            .italic()
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Arah panggung. \(block.content)")
    }

    // MARK: - Transition

    private var transitionRow: some View {
        Text(block.content.uppercased())
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Transisi. \(block.content)")
    }
}

#Preview("Scene Header") {
    VStack(spacing: 16) {
        ScriptLineRowView(block: ScriptBlock(
            orderIndex: 0,
            blockType: .sceneHeader,
            content: "AKT I"
        ))

        ScriptLineRowView(block: ScriptBlock(
            orderIndex: 1,
            blockType: .sceneHeader,
            content: "BAB 1: Pertemuan"
        ))
    }
    .padding()
}

#Preview("Character") {
    VStack(spacing: 16) {
        ScriptLineRowView(block: ScriptBlock(
            orderIndex: 0,
            blockType: .characterName,
            content: "HERMAN"
        ))

        ScriptLineRowView(block: ScriptBlock(
            orderIndex: 1,
            blockType: .characterName,
            content: "MAYA"
        ))
    }
    .padding()
}

#Preview("Dialogue") {
    VStack(spacing: 16) {
        ScriptLineRowView(block: ScriptBlock(
            orderIndex: 0,
            blockType: .dialogue,
            characterName: "Herman",
            content: "Kau tahu, aku sudah menunggumu sejak lama.",
            cueDescription: "sedih"
        ))

        ScriptLineRowView(block: ScriptBlock(
            orderIndex: 1,
            blockType: .dialogue,
            characterName: "Maya",
            content: "Maaf, aku tidak bisa datang lebih awal."
        ))
    }
    .padding()
}

#Preview("Stage Direction") {
    VStack(spacing: 16) {
        ScriptLineRowView(block: ScriptBlock(
            orderIndex: 0,
            blockType: .stageDirection,
            content: "Herman masuk ke ruangan dengan langkah berat."
        ))

        ScriptLineRowView(block: ScriptBlock(
            orderIndex: 1,
            blockType: .stageDirection,
            content: "Lampu redup, suasana sunyi."
        ))
    }
    .padding()
}

#Preview("Transition") {
    VStack(spacing: 16) {
        ScriptLineRowView(block: ScriptBlock(
            orderIndex: 0,
            blockType: .transition,
            content: "FADE IN:"
        ))

        ScriptLineRowView(block: ScriptBlock(
            orderIndex: 1,
            blockType: .transition,
            content: "CUT TO:"
        ))
    }
    .padding()
}
