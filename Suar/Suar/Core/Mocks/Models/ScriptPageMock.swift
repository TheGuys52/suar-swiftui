//
//  ScriptPageMock.swift
//  Suar
//
//  Created by Ari Hasan on 29/08/26.
//

import Foundation
import SwiftData

@Model
final class ScriptPageMock {
    var id: UUID
    var pageNumber: Int

    @Relationship(deleteRule: .cascade)
    var elements: [ScriptElementMock]

    init(
        pageNumber: Int,
        elements: [ScriptElementMock] = []
    ) {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.elements = elements
    }
}
