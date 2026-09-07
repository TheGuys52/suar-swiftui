import Foundation
import SwiftData

@MainActor
final class AudioNoteRepository {
    private let context: ModelContext
    let files: AudioNoteFileStore

    init(container: ModelContainer, files: AudioNoteFileStore = AudioNoteFileStore()) {
        // A dedicated context keeps rollback from undoing reader/onboarding changes.
        context = ModelContext(container)
        context.autosaveEnabled = false
        self.files = files
    }

    func fetchNotes(pageID: UUID) throws -> [AudioNote] {
        try context.fetch(FetchDescriptor<AudioNote>(
            predicate: #Predicate { $0.page?.id == pageID },
            sortBy: [SortDescriptor(\AudioNote.createdAt, order: .reverse)]
        ))
    }

    func save(_ draft: AudioNoteDraft, duration: TimeInterval) throws {
        let noteID = draft.id
        if try !context.fetch(FetchDescriptor<AudioNote>(predicate: #Predicate { $0.id == noteID })).isEmpty {
            try files.completeDraft(draft)
            return
        }
        guard duration.isFinite, duration > 0,
              FileManager.default.fileExists(atPath: files.audioURL(
                scriptID: draft.scriptID, fileName: draft.fileName
              ).path) else {
            throw AudioNoteError.invalidRecording
        }
        let pageID = draft.pageID
        guard let page = try context.fetch(FetchDescriptor<ScriptPage>(
            predicate: #Predicate { $0.id == pageID }
        )).first, page.script?.id == draft.scriptID else {
            throw AudioNoteError.pageMissing
        }
        let number = (try fetchNotes(pageID: pageID).map(\.number).max() ?? 0) + 1
        let note = AudioNote(
            id: draft.id, number: number, createdAt: draft.createdAt,
            duration: duration, fileName: draft.fileName, page: page
        )
        context.insert(note)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        // If this cleanup fails, save is idempotent and can safely be retried.
        try files.completeDraft(draft)
    }

    func rename(_ note: AudioNote, to title: String) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw AudioNoteError.emptyTitle }
        note.customTitle = trimmedTitle
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func delete(_ note: AudioNote, scriptID: UUID) throws {
        try files.deletingFile(scriptID: scriptID, fileName: note.fileName) {
            context.delete(note)
            do {
                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }
}

enum AudioNoteError: LocalizedError {
    case permissionDenied
    case cannotRecord
    case cannotPlay
    case invalidRecording
    case pageMissing
    case emptyTitle

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Izin mikrofon belum diberikan. Aktifkan Mikrofon untuk Suar di Pengaturan."
        case .cannotRecord:
            return "Perekaman belum bisa dimulai. Pastikan mikrofon tersedia, lalu coba lagi."
        case .cannotPlay:
            return "Catatan suara tidak dapat diputar. Berkas mungkin tidak tersedia atau rusak."
        case .invalidRecording:
            return "Belum ada audio yang dapat disimpan. Silakan rekam kembali."
        case .pageMissing:
            return "Halaman untuk catatan ini tidak ditemukan."
        case .emptyTitle:
            return "Nama catatan tidak boleh kosong."
        }
    }
}
