//
//  ContinueReadingSection.swift
//  Suar
//
//  Created by Ivan Putra Pratama on 26/08/26.
//

import SwiftUI

struct ContinueReadingSection: View {
    let scripts: [Script]
    var onSelectScript: ((Script) -> Void)?
    
    var body: some View {
        VStack {
            Text("Continue Reading")
                .bold()
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            if scripts.isEmpty {
                ContinueReadingPlaceholderCard()
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        ForEach(Array(scripts.prefix(5)), id: \.id) { script in
                            ReadingCard(script: script)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onSelectScript?(script)
                                }
                        }
                        
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ContinueReadingPlaceholderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "book.closed.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.themeRed)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text("Belum Ada Bacaan")
                    .font(.headline)
                    .bold()
            }
            
            Text("Naskah yang kamu buka akan tersimpan di sini untuk kamu lanjutkan kapan saja.")
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
