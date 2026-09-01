import Observation
import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @Binding var isShowingFileImporter: Bool
    @State private var searchText = ""
    
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
                            viewModel.didTapLibrary()
                        } label: {
                            Image(systemName: "questionmark")
                                .foregroundStyle(.white)
                                .bold()
                                .frame(width: 44, height: 44)
                                .background(Color.themeRed)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    ContinueReadingSection(scripts: viewModel.recentScripts)
                    VStack(spacing: 16) {
                        AllScriptsSection(scripts: viewModel.allScripts)
                    }
                    
                    Spacer().frame(height: 100)
                }
            }
            .scrollIndicators(.hidden)
            HStack(spacing: 16) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)
                    TextField("Search", text: $searchText)
                    Image(systemName: "mic")
                        .foregroundStyle(.gray)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                Button {
                    viewModel.didTapImport()
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .bold()
                        .frame(width: 56, height: 56)
                        .background(Color.themeRed)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard)
        .task {
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
        .onTapGesture {
            hideKeyboard()
        }
    }
}

#Preview {
    HomeView(
        viewModel: HomeViewModel(),
        isShowingFileImporter: .constant(false)
    )
}
