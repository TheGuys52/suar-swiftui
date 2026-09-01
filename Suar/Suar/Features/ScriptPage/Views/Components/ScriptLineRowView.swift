import SwiftUI

struct ScriptLineRowView: View {
    let line: ScriptLine

    var body: some View {
        switch line.type {
        case .dialogue:
            dialogueRow
        case .description:
            stageDirectionRow
        case .title:
            titleRow
        case .character:
            characterRow
        case .transition:
            transitionRow
        }
    }

    // MARK: - Dialogue

    private var dialogueRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let characterName = line.characterName {
                Text(characterName)
                    .font(.headline)
                    .foregroundStyle(Color.themeRed)
            }

            if let cue = line.cueDescription {
                Text(cue)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
            }

            Text(line.content)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelForDialogue)
    }

    private var accessibilityLabelForDialogue: String {
        var label = line.characterName ?? ""
        if let cue = line.cueDescription {
            label += ", \(cue)"
        }
        label += ". \(line.content)"
        return label
    }

    // MARK: - Stage Direction

    private var stageDirectionRow: some View {
        Text(line.content)
            .font(.body)
            .italic()
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Arah panggung. \(line.content)")
    }

    // MARK: - Title

    private var titleRow: some View {
        Text(line.content)
            .font(.title3)
            .bold()
            .foregroundStyle(Color.themeRed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Judul. \(line.content)")
    }

    // MARK: - Character

    private var characterRow: some View {
        Text(line.content)
            .font(.headline)
            .foregroundStyle(Color.themeRed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Tokoh. \(line.content)")
    }

    // MARK: - Transition

    private var transitionRow: some View {
        Text(line.content)
            .font(.caption)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Transisi. \(line.content)")
    }
}

#Preview("Dialogue") {
    VStack(spacing: 16) {
        ScriptLineRowView(line: ScriptLine(
            characterName: "Herman",
            cueDescription: "sedih",
            content: "Kau tahu, aku sudah menunggumu sejak lama.",
            type: .dialogue
        ))

        ScriptLineRowView(line: ScriptLine(
            characterName: "Maya",
            content: "Maaf, aku tidak bisa datang lebih awal.",
            type: .dialogue
        ))
    }
    .padding()
}

#Preview("Stage Direction") {
    VStack(spacing: 16) {
        ScriptLineRowView(line: ScriptLine(
            content: "Herman masuk ke ruangan dengan langkah berat.",
            type: .description
        ))

        ScriptLineRowView(line: ScriptLine(
            content: "Lampu redup, suasana sunyi.",
            type: .description
        ))
    }
    .padding()
}

#Preview("Title") {
    VStack(spacing: 16) {
        ScriptLineRowView(line: ScriptLine(
            content: "AKT I",
            type: .title
        ))

        ScriptLineRowView(line: ScriptLine(
            content: "BAB 1: Pertemuan",
            type: .title
        ))
    }
    .padding()
}

#Preview("Character") {
    VStack(spacing: 16) {
        ScriptLineRowView(line: ScriptLine(
            content: "PRIA",
            type: .character
        ))

        ScriptLineRowView(line: ScriptLine(
            content: "WANITA",
            type: .character
        ))
    }
    .padding()
}

#Preview("Transition") {
    VStack(spacing: 16) {
        ScriptLineRowView(line: ScriptLine(
            content: "FADE IN:",
            type: .transition
        ))

        ScriptLineRowView(line: ScriptLine(
            content: "CUT TO:",
            type: .transition
        ))
    }
    .padding()
}
