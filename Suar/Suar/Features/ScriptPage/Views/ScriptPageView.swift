import SwiftUI

public struct ScriptPageView: View {
    @Bindable var viewModel: ScriptPageViewModel

    public init(viewModel: ScriptPageViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            mainContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .accessibilityRotor("Adegan", entries: {
            ForEach(viewModel.lines.filter { $0.type == .title }) { line in
                AccessibilityRotorEntry(line.content, id: line.id)
            }
        })
        .accessibilityRotor("Tokoh", entries: {
            ForEach(uniqueCharacterLines) { line in
                AccessibilityRotorEntry(line.characterName ?? "", id: line.id)
            }
        })
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            ScriptPageHeaderView(viewModel: viewModel)
            contentArea
        }
        .overlay(alignment: .bottom) {
            ScriptPageNavigationView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading {
            ProgressView("Memuat naskah...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.lines.isEmpty {
            Text("Tidak ada konten di halaman ini.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            scrollContent
        }
    }

    private var scrollContent: some View {
        ScrollViewReaderContent(viewModel: viewModel)
    }

    private var uniqueCharacterLines: [ScriptLine] {
        var seen = Set<String>()
        return viewModel.lines.filter { line in
            guard let name = line.characterName, !name.isEmpty else { return false }
            if seen.contains(name) { return false }
            seen.insert(name)
            return true
        }
    }
}

private struct ScrollViewReaderContent: View {
    @Bindable var viewModel: ScriptPageViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.lines) { line in
                        ScriptLineRowView(line: line)
                            .id(line.id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 88)
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.currentPageNumber) { _, _ in
                if let firstId = viewModel.lines.first?.id {
                    proxy.scrollTo(firstId, anchor: .top)
                }
            }
            .onAppear {
                if let firstId = viewModel.lines.first?.id {
                    proxy.scrollTo(firstId, anchor: .top)
                }
            }
        }
    }
}

#Preview {
    ScriptPageView(viewModel: ScriptPageViewModel())
}
