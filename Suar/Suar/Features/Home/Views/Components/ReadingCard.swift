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
        VStack {
            HStack {
                Image(systemName: "applescript")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Color.themeRed)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(script.title)
                    .font(.headline)
                    .bold()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ProgressView(value: progressValue)
                .tint(Color.themeRed)
            HStack {
                Text(pageText)
                    .font(.caption)
                Spacer()
                Text(progressText)
                    .font(.caption)
            }
            .padding(.top)
        }
        .padding()
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.themeRed, lineWidth: 2)
        }
        .frame(width: 300)
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
}

#Preview {
    ReadingCard(script: Script(title: "Ruang Tunggu"))
}
