//
//  ContinueReadingSection.swift
//  Suar
//
//  Created by Ivan Putra Pratama on 26/08/26.
//

import SwiftUI

struct ContinueReadingSection: View {
    let scripts: [Script]
    
    var body: some View {
        VStack {
            Text("Continue Reading")
                .bold()
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading )
                .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    if scripts.isEmpty {
                        ContinueReadingPlaceholderCard()
                    } else {
                        ForEach(Array(scripts.prefix(5)), id: \.id) { script in
                            ReadingCard(script: script)
                        }
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }
}

private struct ContinueReadingPlaceholderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "book.closed")
                .font(.title2)
                .foregroundStyle(Color.themeRed)
            
            Text("Belum ada bacaan terakhir")
                .font(.headline)
                .bold()
            
            Text("Buka naskah yang sudah diimpor untuk muncul di sini.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(width: 300, alignment: .leading)
        .background(.thinMaterial)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.themeRed.opacity(0.25), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ContinueReadingSection(scripts: [])
}
