import Observation
import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @Binding var isShowingFileImporter: Bool
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
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
                VStack(spacing: 24) {
                    // MARK: - Sections
                    ContinueReadingSection(
                        scripts: viewModel.recentScripts,
                        onSelectScript: { script in
                            handleScriptSelection(script)
                        }
                    )
                    
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
            
            // Full-screen overlay to dismiss keyboard on background tap
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
                                viewModel.didTapLibrary()
                            }
                        } label: {
                            Image(systemName: "questionmark")
                        }
                        .tint(Color.themeRed)

                    }
                }
        .task {
            #if DEBUG
            await viewModel.seedSamplePDFIfNeeded()
            #endif
            await viewModel.fetchRecentScripts()
            await viewModel.fetchAllScripts()
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.pdf, .jpeg, .png, .image],
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
        .overlay {
            if viewModel.isImporting {
                ProcessingProgressView(
                    scriptTitle: viewModel.currentScriptTitle,
                    progress: viewModel.progressPercentage,
                    statusMessage: viewModel.progressStatusMessage
                )
            }
        }
        .alert("Naskah Berhasil Diproses", isPresented: $viewModel.showSuccessAlert) {
            Button("Buka Reader") {
                if let script = viewModel.newlyProcessedScript {
                    viewModel.onOpenScriptReader?(script)
                }
            }
            Button("Nanti Saja", role: .cancel) { }
        }
        .alert("Terjadi Kesalahan", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Helpers & Subviews
    
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
                
                TextField("Search", text: $searchText)
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
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .bold()
                    .frame(width: 54, height: 54)
                    .background(Color.themeRed)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

#Preview {
    HomeView(
        viewModel: HomeViewModel(),
        isShowingFileImporter: .constant(false)
    )
}
