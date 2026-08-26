//
//  ContinueReadingSection.swift
//  Suar
//
//  Created by Ivan Putra Pratama on 26/08/26.
//

import SwiftUI

struct ContinueReadingSection: View {
    var body: some View {
        VStack {
            Text("Continue Reading")
                .bold()
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading )
                .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack {
                    ReadingCard()
                }
                .padding(.vertical, 6)
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }
}

#Preview {
    ContinueReadingSection()
}
