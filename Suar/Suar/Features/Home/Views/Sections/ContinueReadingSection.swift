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
                        ForEach(Array(scripts.prefix(3)), id: \.id) { script in
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
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(Color.themeRed)
            
            VStack(spacing: 4) {
                Text("Belum Ada Naskah yang Dibaca")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Naskah yang terakhir kamu buka akan muncul di sini agar bisa dilanjutkan dengan cepat.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContinueReadingSection(scripts: [])
}
