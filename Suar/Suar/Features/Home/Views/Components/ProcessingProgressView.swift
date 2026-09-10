//
//  ProcessingProgressView.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import SwiftUI

public struct ProcessingInlineCard: View {
    let scriptTitle: String
    let phase: ProcessingPhase
    var onRetry: (() -> Void)?

    public var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(scriptTitle)
                    .font(.headline)
                    .foregroundStyle(Color.themeTypo)
                    .lineLimit(1)

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(subtitleColor)
                    .lineLimit(1)
            }

            Spacer()

            trailingContent
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Subtitle

    private var subtitleText: String {
        switch phase {
        case .idle:
            return ""
        case .ocr:
            return "Mengekstrak teks..."
        case .parsing(let current, let total):
            return "Menganalisis halaman \(current)/\(total)"
        case .saving:
            return "Menyimpan..."
        case .success:
            return "Naskah Siap Dibaca"
        case .error(let message):
            return message
        }
    }

    private var subtitleColor: Color {
        switch phase {
        case .idle:
            return .secondary
        case .ocr, .parsing, .saving:
            return .secondary
        case .success:
            return Color(hex: "22C55E")
        case .error:
            return Color.themeRed
        }
    }

    // MARK: - Trailing

    @ViewBuilder
    private var trailingContent: some View {
        switch phase {
        case .idle:
            EmptyView()
        case .ocr, .parsing, .saving:
            ProgressView()
                .tint(Color.themeRed)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color(hex: "22C55E"))
                .transition(.scale.combined(with: .opacity))
        case .error:
            Button(action: { onRetry?() }) {
                Text("Coba Lagi")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.themeRed)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Card styling

    private var cardBackgroundView: some View {
        Group {
            switch phase {
            case .success:
                Color(hex: "22C55E").opacity(0.08)
            case .error:
                Color(hex: "EF4444").opacity(0.08)
            default:
                Color.clear
            }
        }
    }

    private var cardBackground: some View {
        ZStack {
            cardBackgroundView
            if !isTerminalPhase {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
    }

    private var isTerminalPhase: Bool {
        switch phase {
        case .success, .error:
            return true
        default:
            return false
        }
    }

    private var borderColor: Color {
        switch phase {
        case .success:
            return Color(hex: "22C55E").opacity(0.3)
        case .error:
            return Color(hex: "EF4444").opacity(0.3)
        default:
            return Color(hex: "EF4444").opacity(0.15)
        }
    }

    private var borderWidth: CGFloat {
        switch phase {
        case .success, .error:
            return 1
        default:
            return 0
        }
    }

    private var accessibilityLabel: String {
        switch phase {
        case .idle:
            return ""
        case .ocr:
            return "Memproses naskah \(scriptTitle). Mengekstrak teks."
        case .parsing(let current, let total):
            return "Memproses naskah \(scriptTitle). Menganalisis halaman \(current) dari \(total)."
        case .saving:
            return "Memproses naskah \(scriptTitle). Menyimpan."
        case .success:
            return "Naskah \(scriptTitle) siap dibaca."
        case .error(let message):
            return "Gagal memproses naskah \(scriptTitle). \(message)"
        }
    }
}

#Preview("OCR") {
    ProcessingInlineCard(scriptTitle: "Ruang Tunggu", phase: .ocr)
        .padding()
}

#Preview("Parsing") {
    ProcessingInlineCard(scriptTitle: "Ruang Tunggu", phase: .parsing(current: 4, total: 9))
        .padding()
}

#Preview("Saving") {
    ProcessingInlineCard(scriptTitle: "Ruang Tunggu", phase: .saving)
        .padding()
}

#Preview("Success") {
    ProcessingInlineCard(
        scriptTitle: "Ruang Tunggu",
        phase: .success(scriptId: UUID(), scriptTitle: "Ruang Tunggu")
    )
    .padding()
}

#Preview("Error") {
    ProcessingInlineCard(
        scriptTitle: "Ruang Tunggu",
        phase: .error(message: "Belum bisa diproses")
    ) {
        print("Retry tapped")
    }
    .padding()
}
