//
//  ScriptView.swift
//  Suar
//
//  Created by Ari Hasan on 26/08/26.
//

import SwiftUI

struct ScriptView: View {
    // MARK: - Page State
    private let totalPages: Int = 17
    @State private var currentPage: Int = 5

    // MARK: - Mock Script Blocks
    private let scriptBlocks: [ScriptBlockDisplay] = [
        ScriptBlockDisplay(lineNumber: 25, character: "WANITA", emotion: "muka kecewa", dialogue: "Aduh aduh, terus yang kaupahami dari dirimu sendiri apa memangnya?"),
        ScriptBlockDisplay(lineNumber: 26, character: "PRIA", emotion: "tercenung", dialogue: "Tidak tahu juga.", continuation: "(kembali duduk) Aku sendiri tidak tahu siapa aku."),
        ScriptBlockDisplay(lineNumber: 27, character: "WANITA", emotion: nil, dialogue: "Kasihan sekali. Rupanya ada yang lebih kesusahan dariku, ya."),
        ScriptBlockDisplay(lineNumber: 28, character: "PRIA", emotion: nil, dialogue: "Kau sendiri, kenapa tidak mencintai anakmu?"),
        ScriptBlockDisplay(lineNumber: 29, character: "WANITA", emotion: "terkejut", dialogue: "Tidak mencintai anakku?"),
        ScriptBlockDisplay(lineNumber: 30, character: "PRIA", emotion: nil, dialogue: "Kan kau sendiri yang bilang tadi. Kau tidak mencintainya, tapi merasa kehilangan kalau dia tidak ada."),
        ScriptBlockDisplay(lineNumber: 31, character: "WANITA", emotion: nil, dialogue: "Ya, itu maksudnya yaaa... begitu! Ah, agak rumit menjelaskannya.", continuation: "(seperti tidak mau memberi penjelasan)"),
        ScriptBlockDisplay(lineNumber: 32, character: "PRIA", emotion: nil, dialogue: "Aku tidak akan memotong, jadi jelaskan saja."),
        ScriptBlockDisplay(lineNumber: 33, character: "WANITA", emotion: "memukul lantai dengan panci", dialogue: "Enak saja! Ingin tahu sekali ya kau!")
    ]

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            header
            progressBar
            scriptContent
            navigationButtons
        }
        .background(Color.themePrimary)
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                // Go Back
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.themeHardShadow)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(white: 0.95))
                    )
            }

            Spacer()

            Text("Ruang Tunggu")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.themeHardShadow)

            Spacer()

            Text("\(currentPage)/\(totalPages)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.themeHardShadow.opacity(0.6))
                .frame(width: 44)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.themeHardShadow.opacity(0.1))
                    .frame(height: 3)

                Rectangle()
                    .fill(Color.themeMaple)
                    .frame(width: geometry.size.width * CGFloat(currentPage) / CGFloat(totalPages), height: 3)
            }
        }
        .frame(height: 3)
    }

    // MARK: - Script Content
    private var scriptContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(scriptBlocks, id: \.lineNumber) { block in
                    scriptBlockView(block)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private func scriptBlockView(_ block: ScriptBlockDisplay) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text("\(block.lineNumber).")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.themeHardShadow.opacity(0.5))
                    .frame(width: 28, alignment: .leading)

                Text(block.character)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.themeMaple)
                    .frame(minWidth: 54, alignment: .leading)

                if let emotion = block.emotion {
                    Text("(\(emotion))")
                        .font(.system(size: 12, weight: .regular))
                        .italic()
                        .foregroundStyle(Color.themeHardShadow.opacity(0.55))
                }
            }

            HStack(alignment: .top, spacing: 0) {
                Text("")
                    .frame(width: 28)
                    .frame(minWidth: 54, alignment: .leading)

                Text(block.dialogue)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.themeHardShadow)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let continuation = block.continuation {
                HStack(alignment: .top, spacing: 0) {
                    Text("")
                        .frame(width: 28)
                        .frame(minWidth: 54, alignment: .leading)

                    Text(continuation)
                        .font(.system(size: 14, weight: .regular))
                        .italic()
                        .foregroundStyle(Color.themeHardShadow.opacity(0.7))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack {
            navButton(direction: .left)
                .opacity(currentPage > 1 ? 1 : 0.4)
                .disabled(currentPage <= 1)

            Spacer()

            navButton(direction: .right)
                .opacity(currentPage < totalPages ? 1 : 0.4)
                .disabled(currentPage >= totalPages)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
    }

    private func navButton(direction: NavDirection) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                if direction == .left && currentPage > 1 {
                    currentPage -= 1
                } else if direction == .right && currentPage < totalPages {
                    currentPage += 1
                }
            }
        } label: {
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.themePrimary)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.themeMaple)
                        .shadow(color: Color.themeMaple.opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
    }
}

// MARK: - Supporting Types
private enum NavDirection {
    case left, right
}

private struct ScriptBlockDisplay: Identifiable {
    let id = UUID()
    let lineNumber: Int
    let character: String
    let emotion: String?
    let dialogue: String
    let continuation: String?

    init(lineNumber: Int, character: String, emotion: String? = nil, dialogue: String, continuation: String? = nil) {
        self.lineNumber = lineNumber
        self.character = character
        self.emotion = emotion
        self.dialogue = dialogue
        self.continuation = continuation
    }
}

#Preview {
    ScriptView()
}
