//
//  ContentView.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 24/08/26.
//

import SwiftUI
import UniformTypeIdentifiers // 👈 Tambahkan ini untuk mendefinisikan tipe file

struct HomeView: View {
    @State private var searchText: String = ""
    @State private var showFilePicker: Bool = false // 👈 State pembuka file picker

    var body: some View {
        // 👈 Tambahkan NavigationStack agar .searchable & .toolbar berfungsi baik
        NavigationStack {
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
                    .shadow(radius: 12)
                }
                .padding()
                
                ContinueReadingSection()
                AllScriptsSection()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .searchable(text: $searchText, prompt: "Search...")
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let selectedFileURL = urls.first else { return }
                    let gotAccess = selectedFileURL.startAccessingSecurityScopedResource()
                    defer {
                        if gotAccess {
                            selectedFileURL.stopAccessingSecurityScopedResource()
                        }
                    }
                    print("Berhasil memilih file: \(selectedFileURL.lastPathComponent)")
                case .failure(let error):
                    print("Gagal memilih file: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
