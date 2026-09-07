//
//  ReadingCard.swift
//  Suar
//
//  Created by Ivan Putra Pratama on 26/08/26.
//

import SwiftUI

struct ReadingCard: View {
    let script: Script
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Label atas
            Text("Terakhir dibuka")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            
            // Bagian utama: Judul, Halaman, dan Chevron
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(script.title)
                        .font(.custom("Georgia", size: 22, relativeTo: .title2))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(pageText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            
            // Indicator Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progressValue, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.themeRed)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var progressValue: Double {
        guard script.pageCount > 0 else { return 0 }
        return min(Double(script.lastReadPage) / Double(script.pageCount), 1.0)
    }
    
    private var pageText: String {
        guard script.pageCount > 0 else {
            return "Baru diimpor"
        }
        return "Halaman \(script.lastReadPage) dari \(script.pageCount)"
    }
    
    private var progressText: String {
        guard script.pageCount > 0 else { return "0%" }
        return "\(Int((progressValue * 100).rounded()))%"
    }

    private var accessibilityLabel: String {
        if script.pageCount > 0 {
            return "Terakhir dibuka, naskah \(script.title). Halaman \(script.lastReadPage) dari \(script.pageCount). Progres baca \(progressText) persen."
        } else {
            return "Terakhir dibuka, naskah \(script.title). Belum ada progres baca."
        }
    }
}

#Preview {
    ReadingCard(script: Script(title: "Ruang Tunggu"))
        .padding()
}
