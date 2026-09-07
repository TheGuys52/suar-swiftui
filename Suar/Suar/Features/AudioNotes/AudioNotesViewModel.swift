import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class AudioNotesViewModel: Identifiable {
    let id = UUID()
    let pageID: UUID
    let scriptID: UUID
    let pageNumber: Int
    let audio = AudioNoteService()
    private(set) var notes: [AudioNote] = []
    private(set) var pendingDraft: AudioNoteDraft?
    private(set) var isRequestingPermission = false
    private(set) var permissionDenied = false
    var errorMessage: String?
    private let repository: AudioNoteRepository
    private let recordOnOpen: Bool
    private var hasOpened = false
    private var isVisible = false
    private var allowsRecording = true
    private var recordingRequestID: UUID?

    var preventsDismissal: Bool { audio.isRecording || isRequestingPermission || pendingDraft != nil }

    init(pageID: UUID, scriptID: UUID, pageNumber: Int, repository: AudioNoteRepository, recordOnOpen: Bool) {
        self.pageID = pageID
        self.scriptID = scriptID
        self.pageNumber = pageNumber
        self.repository = repository
        self.recordOnOpen = recordOnOpen
        audio.onRecordingInterrupted = { [weak self] in
            self?.stopAndSave()
        }
        audio.onPlaybackFailed = { [weak self] in
            self?.errorMessage = AudioNoteError.cannotPlay.localizedDescription
        }
    }

    func open() async {
        guard !hasOpened else { return }
        hasOpened = true
        isVisible = true
        refresh()
        recoverDraft()
        if recordOnOpen, pendingDraft == nil { await startRecording() }
    }

    func startRecording() async {
        guard !audio.isRecording, !isRequestingPermission, pendingDraft == nil, allowsRecording else { return }
        isRequestingPermission = true
        let requestID = UUID()
        recordingRequestID = requestID
        defer { isRequestingPermission = false }
        let granted = await audio.requestPermission()
        guard isVisible, allowsRecording, recordingRequestID == requestID else { return }
        guard granted else {
            permissionDenied = true
            errorMessage = AudioNoteError.permissionDenied.localizedDescription
            return
        }
        permissionDenied = false
        do {
            let draft = try repository.files.createDraft(scriptID: scriptID, pageID: pageID)
            pendingDraft = draft
            try audio.startRecording(at: repository.files.audioURL(scriptID: scriptID, fileName: draft.fileName))
            UIAccessibility.post(notification: .announcement, argument: "Perekaman dimulai")
        } catch {
            if let draft = pendingDraft {
                do {
                    try repository.files.discardDraft(draft)
                    pendingDraft = nil
                } catch {
                    errorMessage = "Rekaman belum dimulai. Draf belum bisa dibersihkan: \(error.localizedDescription)"
                    return
                }
            }
            errorMessage = error.localizedDescription
        }
    }

    func stopAndSave() {
        guard audio.isRecording else { return }
        audio.stopRecording()
        savePendingDraft()
    }

    func savePendingDraft() {
        guard let draft = pendingDraft, !audio.isRecording else { return }
        do {
            let url = repository.files.audioURL(scriptID: scriptID, fileName: draft.fileName)
            try repository.save(draft, duration: audio.duration(at: url))
            pendingDraft = nil
            refresh()
            UIAccessibility.post(notification: .announcement, argument: "Catatan suara tersimpan")
            recoverDraft()
        } catch {
            errorMessage = "Catatan belum tersimpan. Coba simpan lagi atau hapus draf. \(error.localizedDescription)"
        }
    }

    func discardPendingDraft() {
        guard let draft = pendingDraft, !audio.isRecording else { return }
        do {
            try repository.files.discardDraft(draft)
            pendingDraft = nil
            recoverDraft()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func togglePlayback(_ note: AudioNote) {
        do {
            try audio.togglePlayback(
                noteID: note.id,
                url: repository.files.audioURL(scriptID: scriptID, fileName: note.fileName)
            )
        } catch {
            errorMessage = AudioNoteError.cannotPlay.localizedDescription
        }
    }

    func rename(_ note: AudioNote, to title: String) {
        do {
            try repository.rename(note, to: title)
            refresh()
        } catch {
            errorMessage = "Nama belum tersimpan. \(error.localizedDescription)"
        }
    }

    func delete(_ note: AudioNote) {
        if audio.playingNoteID == note.id { audio.stopPlayback() }
        do {
            try repository.delete(note, scriptID: scriptID)
            refresh()
        } catch {
            refresh()
            errorMessage = "Catatan belum berhasil dihapus sepenuhnya. \(error.localizedDescription)"
        }
    }

    func enterBackground() {
        allowsRecording = false
        recordingRequestID = nil
        stopAndSave()
        audio.stopPlayback()
    }

    func becomeActive() { allowsRecording = true }

    func close() {
        isVisible = false
        recordingRequestID = nil
        stopAndSave()
        audio.stopPlayback()
    }

    static func durationLabel(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds.isFinite ? seconds : 0))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private func refresh() {
        do {
            notes = try repository.fetchNotes(pageID: pageID)
        } catch {
            errorMessage = "Catatan suara belum bisa dimuat. \(error.localizedDescription)"
        }
    }

    private func recoverDraft() {
        do {
            let drafts = try repository.files.drafts(scriptID: scriptID, pageID: pageID)
            for draft in drafts {
                // A crash between database save and manifest cleanup must not create a duplicate.
                if notes.contains(where: { $0.id == draft.id }) {
                    try repository.files.completeDraft(draft)
                } else {
                    pendingDraft = draft
                    return
                }
            }
        } catch {
            errorMessage = "Draf rekaman belum bisa dimuat. \(error.localizedDescription)"
        }
    }
}
