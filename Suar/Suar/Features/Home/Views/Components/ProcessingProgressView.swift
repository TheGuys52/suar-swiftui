//
//  ProcessingProgressView.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 30/08/26.
//

import SwiftUI

struct ProcessingProgressView: View {
    let scriptTitle: String
    let progress: Double
    let statusMessage: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Memproses naskah \(scriptTitle)")
                .accessibilityValue("\(Int(progress * 100)) persen. \(statusMessage)")

            card
        }
    }

    private var card: some View {
        VStack(spacing: 20) {
            header
            progressBar
            statusText
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.themeRed.opacity(0.3), lineWidth: 1)
        )
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Color.themeRed)

            Text(scriptTitle)
                .font(.headline)
                .foregroundStyle(Color.themeShadow)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }

    private var progressBar: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
                .progressViewStyle(SuarProgressViewStyle())

            Text("\(Int(progress * 100))%")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Color.themeMaple)
        }
    }

    private var statusText: some View {
        Text(statusMessage)
            .font(.subheadline)
            .foregroundStyle(Color.themeShadow.opacity(0.7))
            .multilineTextAlignment(.center)
    }
}

struct SuarProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.themeShadow.opacity(0.1))
                    .frame(height: 12)

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.themeRed)
                    .frame(width: geometry.size.width * (configuration.fractionCompleted ?? 0), height: 12)
            }
        }
        .frame(height: 12)
    }
}

#Preview {
    ProcessingProgressView(
        scriptTitle: "Ruang Tunggu - Bagian 1",
        progress: 0.45,
        statusMessage: "Mengekstrak teks dari halaman 5..."
    )
}
