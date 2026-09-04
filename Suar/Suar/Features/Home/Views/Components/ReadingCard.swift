//
//  ReadingCard.swift
//  Suar
//
//  Created by Ivan Putra Pratama on 26/08/26.
//

import SwiftUI
import UIKit

struct ReadingCard: View {
    let script: Script
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                backgroundThumbnail
                VStack {
                    Text(script.title)
                        .font(.title2)
                        .bold()
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.white)
                    HStack {
                        VStack {
                            Text(pageText)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(.white)

                            ProgressView(value: progressValue)
                                .tint(.white)

                        }
                        Text(progressText)
                            .font(.title)
                            .foregroundStyle(.white)

                    }
                }
                .padding(8)
                .background(Color.themeRed)
                .shadow(radius: 8, y: -8)
                
            }
            .frame(width: 300, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.themeRed, lineWidth: 2)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
        }
    }

    @ViewBuilder
    private var backgroundThumbnail: some View {
        if let thumbnailData = script.thumbnailData,
           let uiImage = UIImage(data: thumbnailData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 150)
        } else {
            Image("Bitmap")
                .resizable()
                .scaledToFill()
        }
    }
    
    private var progressValue: Double {
        guard script.pageCount > 0 else { return 0 }
        return min(Double(script.lastReadPage) / Double(script.pageCount), 1)
    }
    
    private var pageText: String {
        guard script.pageCount > 0 else {
            return "Baru diimpor"
        }
        return "Bab \(script.lastReadPage) dari \(script.pageCount)"
    }
    
    private var progressText: String {
        guard script.pageCount > 0 else {
            return "0%"
        }
        return "\(Int((progressValue * 100).rounded()))%"
    }

    private var accessibilityLabel: String {
        if script.pageCount > 0 {
            return "Kartu naskah \(script.title). Bab \(script.lastReadPage) dari \(script.pageCount). Progres baca \(progressText) persen."
        } else {
            return "Kartu naskah \(script.title). Belum ada progres baca."
        }
    }
}

#Preview {
    ReadingCard(script: Script(title: "Ruang Tunggu"))
}
