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
                            if #available(iOS 26.0, *) {
                                Image(systemName: "questionmark")
                                    .foregroundStyle(.white)
                                    .bold()
                                    .frame(width: 44, height: 44)
                                    .glassEffect(
                                        .regular
                                            .tint(Color.themeRed)
                                            .interactive()
                                    )
                            } else {
                                Image(systemName: "questionmark")
                                    .foregroundStyle(.white)
                                    .bold()
                                    .frame(width: 44, height: 44)
                                    .background(Color.themeRed)
                            }
                        }
                        .clipShape(Circle())
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
                    if #available(iOS 26.0, *) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .bold()
                            .frame(width: 56, height: 56)
                            .glassEffect(
                                .regular
                                    .tint(Color.themeRed)
                                    .interactive()
                            )
                    } else {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .bold()
                            .frame(width: 56, height: 56)
                            .background(Color.themeRed)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard)
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.pdf, .image],
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
    }
}

#Preview {
    HomeView(
        viewModel: HomeViewModel(),
        isShowingFileImporter: .constant(false)
    )
}
