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
        VStack(alignment: .leading, spacing: 16) {
            Text("Lanjut Membaca")
//                .bold()
                .font(.custom("Georgia", size: 22, relativeTo: .title2))
                .padding(.horizontal)
            
            if let lastOpenedScript = scripts.first {
                ReadingCard(script: lastOpenedScript)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectScript?(lastOpenedScript)
                    }
                    .padding(.horizontal)
            } else {
                ContinueReadingPlaceholderCard()
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
