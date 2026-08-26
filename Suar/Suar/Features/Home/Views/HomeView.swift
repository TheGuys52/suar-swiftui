//
//  ContentView.swift (atau HomeView.swift)
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 24/08/26.
//

import SwiftUI
import UniformTypeIdentifiers // 👈 Wajib ditambahkan untuk menentukan jenis file

struct HomeView: View {
    @State private var searchText = ""
    @State private var showFilePicker = false // 👈 State untuk memunculkan file picker
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Text("Suar")
                            .font(.largeTitle)
                            .bold()
                        Spacer()
                        Button {
                            print("Help button tapped")
                        } label: {
                            Image(systemName: "questionmark")
                                .foregroundStyle(.white)
                                .bold()
                        }
                        .padding()
                        .background(Color.themeRed) // Pastikan Color.themeRed sudah ada di ext Color
                        .clipShape(Circle())
                        .shadow(radius: 12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    ContinueReadingSection()
                    
                    VStack(spacing: 16) {
                        AllScriptsSection()
                    }
                    
                    Spacer().frame(height: 100)
                }
            }
            .scrollIndicators(.hidden)
            
            // MARK: - Floating Bottom Bar
            HStack(spacing: 16) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)
                    TextField("Search", text: $searchText)
                    Image(systemName: "mic")
                        .foregroundStyle(.gray)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                
                Button {
                    showFilePicker = true // 👈 Ubah action tombol plus di sini
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .bold()
                        .frame(width: 56, height: 56)
                        .background(Color.themeRed)
                        .clipShape(Circle())
                        .shadow(radius: 12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard)
        
        // MARK: - File Importer Modifier
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.item], // 👈 Mengizinkan semua jenis file (.item). Ubah ke [.pdf] jika hanya ingin PDF
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedFileURL = urls.first else { return }
                
                // Minta izin sistem untuk mengakses file dari luar aplikasi (misal: iCloud / Downloads)
                let gotAccess = selectedFileURL.startAccessingSecurityScopedResource()
                defer {
                    if gotAccess {
                        selectedFileURL.stopAccessingSecurityScopedResource()
                    }
                }
                
                print("Berhasil memilih file: \(selectedFileURL.lastPathComponent)")
                // Lakukan sesuatu dengan URL file tersebut di sini...
                
            case .failure(let error):
                print("Gagal memilih file: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    HomeView()
}
