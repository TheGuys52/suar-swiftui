import SwiftData
import SwiftUI

public struct ScriptPageView: View {
    @Bindable var viewModel: ScriptPageViewModel
    @FocusState private var searchFieldFocused: Bool
    @State private var showDeleteConfirmation = false
    
    public init(viewModel: ScriptPageViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                if viewModel.isSearching {
                    findNavigator
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                contentArea
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(viewModel.currentPageNumber) / \(viewModel.totalPages)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    // Search
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.isSearching = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            searchFieldFocused = true
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    
                    if viewModel.isVoiceEditMode {
                        // Stop button — hanya saat voice edit mode
                        Button {
                            Task {
                                await viewModel.saveAllVoiceEditedBlocks()
                            }
                            viewModel.toggleVoiceEditMode()
                        } label: {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.red)
                        }
                        .accessibilityLabel("Simpan dan keluar dari mode edit suara")
                    } else {
                        // Menu
                        Menu {
                            Button {
                                viewModel.openAudioNotes()
                            } label: {
                                Label("Catatan Suara", systemImage: "waveform")
                            }
                            .disabled(!viewModel.canAddAudioNotes)
                            
                            Divider()
                            
                            Button {
                                if viewModel.isEditMode {
                                    Task { await viewModel.saveAllEditedBlocks() }
                                }
                                viewModel.toggleEditMode()
                            } label: {
                                Label(
                                    viewModel.isEditMode ? "Selesai" : "Edit",
                                    systemImage: viewModel.isEditMode ? "checkmark" : "pencil"
                                )
                            }
                            
                            if !viewModel.isEditMode {
                                Divider()
                                Button {
                                    viewModel.toggleVoiceEditMode()
                                } label: {
                                    Label("Edit Suara", systemImage: "mic.fill")
                                }
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Hapus", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Opsi naskah")
                        .accessibilityIdentifier("reader.options")
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.audioNotesViewModel, onDismiss: viewModel.refreshAudioNoteCount) { audioNotes in
            AudioNotesView(viewModel: audioNotes)
        }
//        .accessibilityRotor(ScriptRotorType.scenes.rawValue, entries: {
//            ForEach(sceneBlocks) { block in
//                AccessibilityRotorEntry(block.content, id: block.id)
//            }
//        })
//        .accessibilityRotor(ScriptRotorType.characters.rawValue, entries: {
//            ForEach(uniqueCharacterBlocks) { block in
//                AccessibilityRotorEntry(block.characterName ?? "", id: block.id)
//            }
//        })
        .overlay(alignment: .bottom) {
            ScriptPageNavigationView(viewModel: viewModel)
                .padding(.bottom, 16)
        }
        .alert("Hapus Naskah", isPresented: $showDeleteConfirmation) {
            Button("Batal", role: .cancel) {}
            Button("Hapus", role: .destructive) {
                Task {
                    await viewModel.performDelete()
                }
            }
        } message: {
            Text("Naskah ini akan dihapus secara permanen. Apakah Anda yakin?")
        }
        .alert("Terjadi kesalahan", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Find Navigator
    private var findNavigator: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Cari...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .focused($searchFieldFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        viewModel.performSearch(query: viewModel.searchText)
                    }
                    .onChange(of: viewModel.searchText) { _, newValue in
                        if newValue.isEmpty {
                            viewModel.clearSearchResults()
                        } else {
                            viewModel.performSearch(query: newValue)
                        }
                    }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
            
            if !viewModel.searchResults.isEmpty {
                Text("\(viewModel.currentSearchIndex + 1) dari \(viewModel.searchResults.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                
                Button {
                    viewModel.previousSearchResult()
                } label: {
                    Image(systemName: "chevron.up")
                }
                .disabled(viewModel.searchResults.isEmpty)
                
                Button {
                    viewModel.nextSearchResult()
                } label: {
                    Image(systemName: "chevron.down")
                }
                .disabled(viewModel.searchResults.isEmpty)
            }
            
            Button("Selesai") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.dismissSearch()
                }
            }
            .font(.subheadline.bold())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
    
    // MARK: - Content Area
    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading {
            ProgressView("Memuat naskah...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            if viewModel.isEditMode {
                Text("Mode Edit — ketuk teks untuk mengubah")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.themeRed)
            } else if viewModel.isVoiceEditMode {
                Text("Mode Edit Suara — ketuk bagian kata untuk diubah")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.blue)
            }
            scrollContent
        }
    }
    
    private var scrollContent: some View {
        ScrollViewReaderContent(viewModel: viewModel, searchText: viewModel.searchText)
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

// MARK: - ScrollViewReader Content
private struct ScrollViewReaderContent: View {
    @Bindable var viewModel: ScriptPageViewModel
    let searchText: String
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.blocks) { block in
                        if viewModel.isEditMode {
                            EditableBlockRowView(block: block) { newContent in
                                viewModel.markBlockDirty(blockId: block.id, content: newContent)
                            }
                            .id(block.id)
                        } else if viewModel.isVoiceEditMode {
                            VoiceEditBlockRowView(
                                block: block,
                                isSelected: viewModel.selectedVoiceEditBlockId == block.id,
                                onTap: {
                                    viewModel.selectBlockWithAnnouncement(blockId: block.id)
                                },
                                onVoiceEdit: { blockId, newContent in
                                    viewModel.applyVoiceEditToBlock(id: blockId, content: newContent)
                                    // Reset agar bisa edit block lagi
                                        viewModel.selectedVoiceEditBlockId = nil
                                }
                            )
                            .id(block.id)
                        } else {
                            ScriptLineRowView(
                                block: block,
                                searchText: blockMatchesSearch(block) ? searchText : nil
                            )
                            .id(block.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.currentPageNumber) { _, _ in
                if let firstId = viewModel.blocks.first?.id {
                    proxy.scrollTo(firstId, anchor: .top)
                }
            }
            .onChange(of: viewModel.currentSearchIndex) { _, _ in
                scrollToCurrentSearchResult(proxy: proxy)
            }
            .onAppear {
                if let firstId = viewModel.blocks.first?.id {
                    proxy.scrollTo(firstId, anchor: .top)
                }
            }
        }
    }
    
    private func blockMatchesSearch(_ block: ScriptBlock) -> Bool {
        guard !searchText.isEmpty else { return false }
        return viewModel.searchResults.contains { $0.blockId == block.id }
    }
    
    private func scrollToCurrentSearchResult(proxy: ScrollViewProxy) {
        guard viewModel.currentSearchIndex < viewModel.searchResults.count else { return }
        let blockId = viewModel.searchResults[viewModel.currentSearchIndex].blockId
        withAnimation {
            proxy.scrollTo(blockId, anchor: .center)
        }
    }
}

#Preview {
    ScriptPageView(viewModel: ScriptPageViewModel())
}
