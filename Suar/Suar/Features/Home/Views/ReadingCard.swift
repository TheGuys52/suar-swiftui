//
//  ReadingCard.swift
//  Suar
//
//  Created by Ivan Putra Pratama on 26/08/26.
//

import SwiftUI

struct ReadingCard: View {
    @State private var progress = 0.5

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "applescript")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Color.themeRed)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                Text("Lorem Ipsum dolor sit")
                    .font(.title)
                    .bold()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ProgressView(value: progress)
                .tint(Color.themeRed)
            HStack {
                Text("Bab 11 dari 100")
                    .font(.caption)
                Spacer()
                Text("11%")
                    .font(.caption)
            }
            .padding(.top)
        }
        .padding()
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.themeRed, lineWidth: 2)
        }
        .frame(maxWidth: 300)
    }
}

#Preview {
    ReadingCard()
}
