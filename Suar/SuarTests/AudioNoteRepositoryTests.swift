import Foundation
@testable import Suar
import SwiftData
import XCTest

final class AudioNoteRepositoryTests: XCTestCase {
    @MainActor
    func testRenamePersistsWithoutChangingAudioAndRejectsBlankName() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let storeURL = root.appendingPathComponent("rename.store")
        let files = AudioNoteFileStore(root: root.appendingPathComponent("audio"))
        let draft: AudioNoteDraft
        do {
            let container = try makeContainer(url: storeURL)
            let script = try insertScript(container)
            let pageID = script.pages[0].id
            let repository = AudioNoteRepository(container: container, files: files)
            draft = try makeDraft(files, scriptID: script.id, pageID: pageID)
            try repository.save(draft, duration: 4)
            let note = try XCTUnwrap(repository.fetchNotes(pageID: pageID).first)
            XCTAssertEqual(note.title, "Catatan 1")
            try repository.rename(note, to: "  Versi lebih tenang  ")
            XCTAssertThrowsError(try repository.rename(note, to: " \n "))
            XCTAssertEqual(note.title, "Versi lebih tenang")
        }
        let reopened = try makeContainer(url: storeURL)
        let repository = AudioNoteRepository(container: reopened, files: files)
        let note = try XCTUnwrap(repository.fetchNotes(pageID: draft.pageID).first)
        XCTAssertEqual(note.title, "Versi lebih tenang")
        XCTAssertEqual(note.id, draft.id)
        XCTAssertEqual(note.fileName, draft.fileName)
        XCTAssertEqual(note.duration, 4)
        XCTAssertEqual(try Data(contentsOf: files.audioURL(
            scriptID: draft.scriptID, fileName: note.fileName
        )), Data("recording fixture".utf8))
    }

    @MainActor
    func testExistingOnboardingStoreMigratesWithoutLosingScriptOrReadingPosition() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let storeURL = root.appendingPathComponent("migration.store")
        let scriptID: UUID
        do {
            let schema = Schema([
                PreAudioSchema.Script.self, PreAudioSchema.ScriptPage.self, PreAudioSchema.ScriptBlock.self
            ])
            let container = try ModelContainer(
                for: schema, configurations: ModelConfiguration(schema: schema, url: storeURL)
            )
            let script = PreAudioSchema.Script(title: "Existing script", lastReadPage: 2, pageCount: 2)
            scriptID = script.id
            let page = PreAudioSchema.ScriptPage(pageNumber: 2, rawExtractedText: "Dialog lama", script: script)
            page.blocks = [PreAudioSchema.ScriptBlock(
                orderIndex: 0, blockType: .dialogue, content: "Dialog lama", page: page
            )]
            script.pages = [PreAudioSchema.ScriptPage(pageNumber: 1, script: script), page]
            container.mainContext.insert(script)
            try container.mainContext.save()
        }
        let migrated = try makeContainer(url: storeURL)
        let script = try XCTUnwrap(migrated.mainContext.fetch(FetchDescriptor<Script>()).first)
        XCTAssertEqual(script.id, scriptID)
        XCTAssertEqual(script.title, "Existing script")
        XCTAssertEqual(script.lastReadPage, 2)
        XCTAssertEqual(script.pages.count, 2)
        let secondPage = try XCTUnwrap(script.pages.first { $0.pageNumber == 2 })
        XCTAssertEqual(secondPage.blocks.first?.content, "Dialog lama")
        XCTAssertTrue(secondPage.audioNotes.isEmpty)
        let repository = AudioNoteRepository(
            container: migrated, files: AudioNoteFileStore(root: root.appendingPathComponent("audio"))
        )
        let draft = try makeDraft(repository.files, scriptID: scriptID, pageID: secondPage.id)
        try repository.save(draft, duration: 2)
        XCTAssertEqual(try repository.fetchNotes(pageID: secondPage.id).count, 1)
    }

    @MainActor
    func testMultipleNotesStayOnTheirPageAfterReopeningStore() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let storeURL = root.appendingPathComponent("test.store")
        let files = AudioNoteFileStore(root: root.appendingPathComponent("audio"))
        let scriptID: UUID
        let firstPageID: UUID
        let secondPageID: UUID
        let firstDraft: AudioNoteDraft
        do {
            let container = try makeContainer(url: storeURL)
            let script = try insertScript(container)
            scriptID = script.id
            firstPageID = script.pages[0].id
            secondPageID = script.pages[1].id
            let repository = AudioNoteRepository(container: container, files: files)
            firstDraft = try makeDraft(files, scriptID: scriptID, pageID: firstPageID)
            let secondDraft = try makeDraft(files, scriptID: scriptID, pageID: firstPageID)
            let otherPageDraft = try makeDraft(files, scriptID: scriptID, pageID: secondPageID)
            try repository.save(firstDraft, duration: 3)
            try repository.save(secondDraft, duration: 5)
            try repository.save(otherPageDraft, duration: 7)
            // Retrying a save after an interrupted manifest cleanup must be harmless.
            try repository.save(firstDraft, duration: 3)
            XCTAssertTrue(try files.drafts(scriptID: scriptID, pageID: firstPageID).isEmpty)
        }
        let reopened = try makeContainer(url: storeURL)
        let repository = AudioNoteRepository(container: reopened, files: files)
        let firstNotes = try repository.fetchNotes(pageID: firstPageID)
        XCTAssertEqual(firstNotes.count, 2)
        XCTAssertEqual(Set(firstNotes.map(\.number)), [1, 2])
        XCTAssertEqual(Set(firstNotes.map(\.duration)), [3, 5])
        XCTAssertEqual(try repository.fetchNotes(pageID: secondPageID).count, 1)
        let saved = try XCTUnwrap(firstNotes.first { $0.id == firstDraft.id })
        XCTAssertEqual(saved.page?.id, firstPageID)
        XCTAssertTrue(FileManager.default.fileExists(atPath: files.audioURL(
            scriptID: scriptID, fileName: saved.fileName
        ).path))
    }

    @MainActor
    func testFailedSaveKeepsDraftRecoverableAndRejectsWrongScript() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let files = AudioNoteFileStore(root: root.appendingPathComponent("audio"))
        let container = try makeContainer(url: root.appendingPathComponent("test.store"))
        let script = try insertScript(container)
        let pageID = script.pages[0].id
        let repository = AudioNoteRepository(container: container, files: files)
        let draft = try makeDraft(files, scriptID: script.id, pageID: pageID)
        XCTAssertThrowsError(try repository.save(draft, duration: 0))
        XCTAssertEqual(try files.drafts(scriptID: script.id, pageID: pageID).map(\.id), [draft.id])
        XCTAssertTrue(try repository.fetchNotes(pageID: pageID).isEmpty)
        try repository.save(draft, duration: 2)
        XCTAssertEqual(try repository.fetchNotes(pageID: pageID).count, 1)

        let wrongScriptDraft = try makeDraft(files, scriptID: UUID(), pageID: pageID)
        XCTAssertThrowsError(try repository.save(wrongScriptDraft, duration: 2))
        XCTAssertEqual(try repository.fetchNotes(pageID: pageID).count, 1)
    }

    @MainActor
    func testDeletingOneNotePreservesOtherNotesAndFiles() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let files = AudioNoteFileStore(root: root.appendingPathComponent("audio"))
        let container = try makeContainer(url: root.appendingPathComponent("test.store"))
        let script = try insertScript(container)
        let pageID = script.pages[0].id
        let repository = AudioNoteRepository(container: container, files: files)
        let firstDraft = try makeDraft(files, scriptID: script.id, pageID: pageID)
        let secondDraft = try makeDraft(files, scriptID: script.id, pageID: pageID)
        try repository.save(firstDraft, duration: 2)
        try repository.save(secondDraft, duration: 2)
        let toDelete = try XCTUnwrap(repository.fetchNotes(pageID: pageID).first { $0.id == firstDraft.id })
        try repository.delete(toDelete, scriptID: script.id)
        XCTAssertEqual(try repository.fetchNotes(pageID: pageID).map(\.id), [secondDraft.id])
        XCTAssertFalse(FileManager.default.fileExists(atPath: files.audioURL(
            scriptID: script.id, fileName: firstDraft.fileName
        ).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: files.audioURL(
            scriptID: script.id, fileName: secondDraft.fileName
        ).path))
    }

    @MainActor
    func testScriptDeletionCascadesToNotesAndAudioIncludingDrafts() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let files = AudioNoteFileStore(root: root.appendingPathComponent("audio"))
        let container = try makeContainer(url: root.appendingPathComponent("test.store"))
        let script = try insertScript(container)
        let scriptID = script.id
        let pageID = script.pages[0].id
        let repository = AudioNoteRepository(container: container, files: files)
        let draft = try makeDraft(files, scriptID: scriptID, pageID: pageID)
        try repository.save(draft, duration: 2)
        _ = try makeDraft(files, scriptID: scriptID, pageID: pageID)
        try files.deletingScript(scriptID) {
            container.mainContext.delete(script)
            try container.mainContext.save()
        }
        let reopened = try makeContainer(url: root.appendingPathComponent("test.store"))
        XCTAssertTrue(try reopened.mainContext.fetch(FetchDescriptor<AudioNote>()).isEmpty)
        XCTAssertTrue(try reopened.mainContext.fetch(FetchDescriptor<ScriptPage>()).isEmpty)
        XCTAssertTrue(try files.drafts(scriptID: scriptID, pageID: pageID).isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: files.audioURL(
            scriptID: scriptID, fileName: draft.fileName
        ).path))
    }

    func testFailedDeletionRestoresAudio() throws {
        struct SaveFailure: Error {}
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let files = AudioNoteFileStore(root: root)
        let draft = try makeDraft(files, scriptID: UUID(), pageID: UUID())
        let url = files.audioURL(scriptID: draft.scriptID, fileName: draft.fileName)
        XCTAssertThrowsError(try files.deletingFile(scriptID: draft.scriptID, fileName: draft.fileName) {
            throw SaveFailure()
        })
        XCTAssertEqual(try Data(contentsOf: url), Data("recording fixture".utf8))
        XCTAssertThrowsError(try files.deletingScript(draft.scriptID) { throw SaveFailure() })
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    @MainActor
    private func makeContainer(url: URL) throws -> ModelContainer {
        let schema = Schema([Script.self, ScriptPage.self, ScriptBlock.self, AudioNote.self])
        return try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
    }

    @MainActor
    private func insertScript(_ container: ModelContainer) throws -> Script {
        let script = Script(title: "Audio test", pageCount: 2)
        script.pages = [ScriptPage(pageNumber: 1, script: script), ScriptPage(pageNumber: 2, script: script)]
        container.mainContext.insert(script)
        try container.mainContext.save()
        return script
    }

    private func temporaryDirectory() -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func makeDraft(_ files: AudioNoteFileStore, scriptID: UUID, pageID: UUID) throws -> AudioNoteDraft {
        let draft = try files.createDraft(scriptID: scriptID, pageID: pageID)
        try Data("recording fixture".utf8).write(to: files.audioURL(scriptID: scriptID, fileName: draft.fileName))
        return draft
    }
}
