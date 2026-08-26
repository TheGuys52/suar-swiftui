//
//  AllScriptsSection.swift
//  Suar
//
//  Created by Ivan Putra Pratama on 26/08/26.
//

import SwiftUI

struct AllScriptsSection: View {
    var body: some View {
        VStack {
            HStack {
                Text("All Scripts")
                    .bold()
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                Menu {
                    Button("Terbaru", action: {})
                    Button("Terlama", action: {})
                    Button("Abjad (A-Z)", action: {})
                    Button("Abjad (Z-A)", action: {})
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundStyle(.white)
                        .bold()
                }
                .padding(12)
                .background(Color.themeRed)
                .clipShape(Circle())
                .shadow(radius: 12)
            }
            .padding(.horizontal)
            ScrollView {
                AllScriptList()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AllScriptsSection()
}
