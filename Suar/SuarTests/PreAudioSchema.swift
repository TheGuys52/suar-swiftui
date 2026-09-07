import Foundation
@testable import Suar
import SwiftData

// Snapshot of the f/onboarding storage schema before audio notes, for migration regression testing.
enum PreAudioSchema {
    @Model
    public final class Script {
        @Attribute(.unique) public var id: UUID
        public var title: String
        public var createdAt: Date
        public var lastAccessedAt: Date
        public var lastReadPage: Int
        public var pageCount: Int
        public var sourceFileName: String
        
        @Relationship(deleteRule: .cascade, inverse: \ScriptPage.script)
        public var pages: [ScriptPage] = []
        
        public init(
            id: UUID = UUID(),
            title: String,
            createdAt: Date = Date(),
            lastAccessedAt: Date = Date(),
            lastReadPage: Int = 1,
            pageCount: Int = 0,
            sourceFileName: String = "",
            pages: [ScriptPage] = []
        ) {
            self.id = id
            self.title = title
            self.createdAt = createdAt
            self.lastAccessedAt = lastAccessedAt
            self.lastReadPage = lastReadPage
            self.pageCount = pageCount
            self.sourceFileName = sourceFileName
            self.pages = pages
        }
    }

    @Model
    public final class ScriptPage {
        @Attribute(.unique) public var id: UUID
        public var pageNumber: Int
        public var rawExtractedText: String
        
        public var script: Script?
        
        @Relationship(deleteRule: .cascade, inverse: \ScriptBlock.page)
        public var blocks: [ScriptBlock] = []
        
        public init(
            id: UUID = UUID(),
            pageNumber: Int,
            rawExtractedText: String = "",
            script: Script? = nil,
            blocks: [ScriptBlock] = []
        ) {
            self.id = id
            self.pageNumber = pageNumber
            self.rawExtractedText = rawExtractedText
            self.script = script
            self.blocks = blocks
        }
    }

    @Model
    public final class ScriptBlock {
        @Attribute(.unique) public var id: UUID
        public var orderIndex: Int
        public var blockType: ScriptBlockType
        public var characterName: String?
        public var content: String
        public var cueDescription: String?
        public var startPageNumber: Int?
        public var endPageNumber: Int?

        public var page: ScriptPage?

        public init(
            id: UUID = UUID(),
            orderIndex: Int,
            blockType: ScriptBlockType,
            characterName: String? = nil,
            content: String,
            cueDescription: String? = nil,
            startPageNumber: Int? = nil,
            endPageNumber: Int? = nil,
            page: ScriptPage? = nil
        ) {
            self.id = id
            self.orderIndex = orderIndex
            self.blockType = blockType
            self.characterName = characterName
            self.content = content
            self.cueDescription = cueDescription
            self.startPageNumber = startPageNumber
            self.endPageNumber = endPageNumber
            self.page = page
        }
    }
}
