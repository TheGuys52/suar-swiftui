//
//  ScriptElemetMock.swift
//  Suar
//
//  Created by Ari Hasan on 29/08/26.
//

import Foundation
import SwiftData

enum ScriptElementTypeMock: String, Codable {
    case text
    case description
    case dialogue
}

@Model
final class ScriptElementMock {
    var id: UUID
    var type: ScriptElementTypeMock
    var content: String
    var order: Int

    init(
        type: ScriptElementTypeMock,
        content: String,
        order: Int
    ) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.order = order
    }
}
