import SwiftUI

struct AudioNotesView: View {
    @Bindable var viewModel: AudioNotesViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var noteToDelete: AudioNote?
    @State private var noteToRename: AudioNote?
    @State private var editedTitle = ""
    @State private var showRename = false
    @State private var showDiscardConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    if viewModel.notes.isEmpty {
                        Text("Belum ada rekaman")
                            .foregroundStyle(.secondary)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(viewModel.notes) { note in
                            noteRow(note)
                        }
                    }
                }
                .listStyle(.plain)
                .safeAreaInset(edge: .bottom) {
                    FloatingRecordButton(viewModel: viewModel)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Catatan suara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Catatan suara").font(.headline)
                        Text("Halaman \(viewModel.pageNumber)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Selesai") { dismiss() }
                        .disabled(viewModel.preventsDismissal)
                }
            }
            .tint(Color.themeRed)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.preventsDismissal)
        .task { await viewModel.open() }
        .onDisappear { viewModel.close() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { viewModel.enterBackground() }
            if phase == .active { viewModel.becomeActive() }
        }
        .alert("Catatan suara", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            if viewModel.permissionDenied {
                Button("Buka Pengaturan") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Ubah nama", isPresented: $showRename) {
            TextField("Nama catatan", text: $editedTitle)
                .textInputAutocapitalization(.sentences)
                .accessibilityIdentifier("audioNotes.renameField")
            Button("Batal", role: .cancel) { noteToRename = nil }
            Button("Simpan") {
                if let note = noteToRename { viewModel.rename(note, to: editedTitle) }
                noteToRename = nil
            }
            .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .confirmationDialog("Hapus catatan suara?", isPresented: Binding(
            get: { noteToDelete != nil },
            set: { if !$0 { noteToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Hapus catatan", role: .destructive) {
                if let note = noteToDelete { viewModel.delete(note) }
                noteToDelete = nil
            }
            Button("Batal", role: .cancel) { noteToDelete = nil }
        }
        .confirmationDialog("Hapus rekaman yang belum tersimpan?", isPresented: $showDiscardConfirmation) {
            Button("Hapus draf", role: .destructive) { viewModel.discardPendingDraft() }
            Button("Batal", role: .cancel) {}
        }
    }

    private func noteRow(_ note: AudioNote) -> some View {
        let isPlaying = viewModel.audio.playingNoteID == note.id && viewModel.audio.isPlaying
        return HStack(spacing: 12) {
            Button {
                viewModel.togglePlayback(note)
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.audio.isRecording || viewModel.isRequestingPermission)
            .accessibilityLabel("\(isPlaying ? "Jeda" : "Putar") \(note.title)")
            .accessibilityIdentifier("audioNotes.play.\(note.id)")

            VStack(alignment: .leading, spacing: 3) {
                Text(note.title)
                    .font(.body.weight(.medium))
                    .lineLimit(2)
                HStack(spacing: 5) {
                    Text(note.createdAt, format: .dateTime.day().month(.abbreviated))
                    Text("·")
                    Text(AudioNotesViewModel.durationLabel(note.duration))
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            Menu {
                Button {
                    noteToRename = note
                    editedTitle = note.title
                    showRename = true
                } label: {
                    Label("Ubah nama", systemImage: "pencil")
                }
                Button(role: .destructive) { noteToDelete = note } label: {
                    Label("Hapus", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 44, height: 44)
            }
            .tint(.secondary)
            .disabled(viewModel.audio.isRecording || viewModel.isRequestingPermission)
            .accessibilityLabel("Opsi \(note.title)")
            .accessibilityIdentifier("audioNotes.options.\(note.id)")
        }
        .padding(.vertical, 4)
    }
}

private struct FloatingRecordButton: View {
    @Bindable var viewModel: AudioNotesViewModel

    var body: some View {
        VStack(spacing: 12) {
            Button {
                if viewModel.audio.isRecording {
                    viewModel.stopAndSave()
                } else {
                    Task { await viewModel.startRecording() }
                }
            } label: {
                Image(systemName: viewModel.audio.isRecording ? "stop.fill" : "mic.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Color.themeRed)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .disabled(viewModel.isRequestingPermission)
            .accessibilityLabel(viewModel.audio.isRecording ? "Hentikan perekaman" : "Mulai merekam")
            .accessibilityIdentifier("audioNotes.recordButton")

            if viewModel.audio.isRecording {
                Text(AudioNotesViewModel.durationLabel(viewModel.audio.elapsed))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Durasi perekaman \(AudioNotesViewModel.durationLabel(viewModel.audio.elapsed))")
            }
        }
        .frame(maxWidth: .infinity)
    }
}
