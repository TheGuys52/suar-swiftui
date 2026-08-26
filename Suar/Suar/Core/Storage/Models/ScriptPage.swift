//
//  ScriptPage.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import Foundation
import SwiftData

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
