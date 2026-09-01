import SwiftData
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
        .accessibilityRotor(ScriptRotorType.scenes.rawValue, entries: {
            ForEach(sceneBlocks) { block in
                AccessibilityRotorEntry(block.content, id: block.id)
            }
        })
        .accessibilityRotor(ScriptRotorType.characters.rawValue, entries: {
            ForEach(uniqueCharacterBlocks) { block in
                AccessibilityRotorEntry(block.characterName ?? "", id: block.id)
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
        } else if viewModel.blocks.isEmpty {
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

    private var sceneBlocks: [ScriptBlock] {
        viewModel.blocks.filter { $0.blockType == .sceneHeader }
    }

    private var uniqueCharacterBlocks: [ScriptBlock] {
        var seen = Set<String>()
        return viewModel.blocks.filter { block in
            guard let name = block.characterName, !name.isEmpty else { return false }
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
                    ForEach(viewModel.blocks) { block in
                        ScriptLineRowView(block: block)
                            .id(block.id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 88)
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.currentPageNumber) { _, _ in
                if let firstId = viewModel.blocks.first?.id {
                    proxy.scrollTo(firstId, anchor: .top)
                }
            }
            .onAppear {
                if let firstId = viewModel.blocks.first?.id {
                    proxy.scrollTo(firstId, anchor: .top)
                }
            }
        }
    }
}

#Preview {
    ScriptPageView(viewModel: ScriptPageViewModel())
}
