//
//  ContentView.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 24/08/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            HStack {
                Text("Suar")
                    .font(.title)
                    .bold()
                Spacer()
                Button {
                    print("button")
                } label: {
                    Image(systemName: "questionmark")
                        .foregroundStyle(.white)
                        .bold()
                }
                .padding()
                .background(Color.themeRed)
                .clipShape(Circle())
            }
            .padding()
            ContinueReadingSection()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    HomeView()
}
