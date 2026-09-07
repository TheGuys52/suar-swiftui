import Foundation

struct AudioNoteDraft: Codable, Identifiable {
    let id: UUID
    let scriptID: UUID
    let pageID: UUID
    let createdAt: Date

    var fileName: String { "\(id.uuidString).m4a" }
}

/// Audio lives outside SwiftData. A small manifest lets an unfinished save be recovered.
struct AudioNoteFileStore {
    let root: URL
    private let manager = FileManager.default

    init(root: URL? = nil) {
        self.root = root ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AudioNotes", isDirectory: true)
    }

    func audioURL(scriptID: UUID, fileName: String) -> URL {
        directory(scriptID: scriptID).appendingPathComponent(fileName)
    }

    func createDraft(scriptID: UUID, pageID: UUID) throws -> AudioNoteDraft {
        let draft = AudioNoteDraft(id: UUID(), scriptID: scriptID, pageID: pageID, createdAt: Date())
        try manager.createDirectory(at: directory(scriptID: scriptID), withIntermediateDirectories: true)
        try JSONEncoder().encode(draft).write(to: manifestURL(draft), options: .atomic)
        return draft
    }

    func drafts(scriptID: UUID, pageID: UUID) throws -> [AudioNoteDraft] {
        let folder = directory(scriptID: scriptID)
        guard manager.fileExists(atPath: folder.path) else { return [] }
        return try manager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .map { try JSONDecoder().decode(AudioNoteDraft.self, from: Data(contentsOf: $0)) }
            .filter { $0.pageID == pageID && $0.scriptID == scriptID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func completeDraft(_ draft: AudioNoteDraft) throws {
        try removeIfPresent(manifestURL(draft))
    }

    func discardDraft(_ draft: AudioNoteDraft) throws {
        try removeIfPresent(audioURL(scriptID: draft.scriptID, fileName: draft.fileName))
        try completeDraft(draft)
    }

    /// Move first, then commit metadata; a failed database save restores the audio.
    func deletingFile(scriptID: UUID, fileName: String, commit: () throws -> Void) throws {
        try deleting(audioURL(scriptID: scriptID, fileName: fileName), commit: commit)
    }

    func deletingScript(_ scriptID: UUID, commit: () throws -> Void) throws {
        try deleting(directory(scriptID: scriptID), commit: commit)
    }

    private func deleting(_ source: URL, commit: () throws -> Void) throws {
        let staged = source.appendingPathExtension("deleting-\(UUID().uuidString)")
        let exists = manager.fileExists(atPath: source.path)
        if exists { try manager.moveItem(at: source, to: staged) }
        do {
            try commit()
        } catch {
            if exists { try manager.moveItem(at: staged, to: source) }
            throw error
        }
        if exists { try manager.removeItem(at: staged) }
    }

    private func directory(scriptID: UUID) -> URL {
        root.appendingPathComponent(scriptID.uuidString, isDirectory: true)
    }

    private func manifestURL(_ draft: AudioNoteDraft) -> URL {
        directory(scriptID: draft.scriptID).appendingPathComponent("\(draft.id.uuidString).json")
    }

    private func removeIfPresent(_ url: URL) throws {
        if manager.fileExists(atPath: url.path) { try manager.removeItem(at: url) }
    }
}
