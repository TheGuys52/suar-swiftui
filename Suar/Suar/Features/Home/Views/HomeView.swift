//
//  HomeView.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @Binding var isShowingFileImporter: Bool
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    init(viewModel: HomeViewModel, isShowingFileImporter: Binding<Bool>) {
        self.viewModel = viewModel
        self._isShowingFileImporter = isShowingFileImporter

        if let georgia = UIFont(name: "Georgia", size: 34) {
            UINavigationBar.appearance().largeTitleTextAttributes = [
                .font: georgia,
                .foregroundColor: UIColor(Color.themeTypo)
            ]
        }
    }

    private var filteredScripts: [Script] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return viewModel.allScripts
        } else {
            return viewModel.allScripts.filter {
                $0.title.localizedCaseInsensitiveContains(query)
            }
        }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 28) {
                    ContinueReadingSection(
                        scripts: viewModel.recentScripts,
                        onSelectScript: { script in
                            handleScriptSelection(script)
                        }
                    )

                    if viewModel.processingPhase != .idle {
                        ProcessingInlineCard(
                            scriptTitle: viewModel.currentScriptTitle,
                            phase: viewModel.processingPhase,
                            onRetry: { viewModel.retryLastProcessing() }
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    AllScriptsSection(
                        scripts: filteredScripts,
                        onSelectScript: { script in
                            handleScriptSelection(script)
                        }
                    )
                }
                .padding(.bottom, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                bottomSearchBar
            }

            if isSearchFocused {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isSearchFocused = false
                            hideKeyboard()
                        }
                    }
            }
        }
        .navigationTitle("Suar")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if isSearchFocused {
                        isSearchFocused = false
                        hideKeyboard()
                    } else {
                        viewModel.didTapShowOnboarding()
                    }
                } label: {
                    Image(systemName: "questionmark")
                }
                .accessibilityLabel("Panduan Aplikasi")
            }
        }
        .task {
            await viewModel.seedIfNeeded()
            await viewModel.fetchRecentScripts()
            await viewModel.fetchAllScripts()
        }
        .onAppear {
            Task {
                await viewModel.fetchRecentScripts()
                await viewModel.fetchAllScripts()
            }
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.pdf, .jpeg, .png, .heic, .docx, .doc, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                viewModel.handleSelectedFile(result: .success(url))
            case .failure(let error):
                viewModel.handleSelectedFile(result: .failure(error))
            }
        }
        .alert("Terjadi Kesalahan", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func handleScriptSelection(_ script: Script) {
        if isSearchFocused {
            isSearchFocused = false
            hideKeyboard()
        } else {
            viewModel.didTapScript(id: script.id)
        }
    }

    private var bottomSearchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)

                TextField("Cari Naskah", text: $searchText)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                } else {
                    Image(systemName: "mic")
                        .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

            Button {
                viewModel.didTapImport()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "Silahkan pilih file naskah yang mau ditambahkan."
                    )
                }
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .bold()
                    .frame(width: 54, height: 54)
                    .background(Color.themeRed)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Tambah Naskah")
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

#Preview("Empty") {
    HomeView(viewModel: HomeViewModel(), isShowingFileImporter: .constant(false))
}

#Preview("Processing") {
    let vm = HomeViewModel()
    vm.currentScriptTitle = "Ruang Tunggu"
    vm.processingPhase = .parsing(current: 4, total: 9)
    return HomeView(viewModel: vm, isShowingFileImporter: .constant(false))
}

#Preview("With Data") {
    let vm = HomeViewModel()
    vm.recentScripts = [
        Script(title: "Ruang Tunggu", createdAt: Date(), lastReadPage: 12, pageCount: 24)
    ]
    vm.allScripts = [
        Script(title: "Ruang Tunggu - Bagian 1", createdAt: Date(), lastReadPage: 1, pageCount: 24),
        Script(title: "Ruang Tunggu - Bagian 2", createdAt: Date().addingTimeInterval(-86400), lastReadPage: 1, pageCount: 18)
    ]
    return HomeView(viewModel: vm, isShowingFileImporter: .constant(false))
}
