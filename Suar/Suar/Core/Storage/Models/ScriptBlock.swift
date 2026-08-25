//
//  ScriptBlock.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import Foundation
import SwiftData

@Model
public final class ScriptBlock {
    @Attribute(.unique) public var id: UUID
    public var orderIndex: Int
    public var blockType: ScriptBlockType
    public var characterName: String?
    public var content: String
    public var cueDescription: String?
    
    public var page: ScriptPage?
    
    public init(
        id: UUID = UUID(),
        orderIndex: Int,
        blockType: ScriptBlockType,
        characterName: String? = nil,
        content: String,
        cueDescription: String? = nil,
        page: ScriptPage? = nil
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.blockType = blockType
        self.characterName = characterName
        self.content = content
        self.cueDescription = cueDescription
        self.page = page
    }
}
