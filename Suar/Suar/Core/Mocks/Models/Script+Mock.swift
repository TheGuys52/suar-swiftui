//
//  Script+Mock.swift
//  Suar
//
//  Created by Ari Hasan on 26/08/26.
//

import Foundation
import SwiftData

@Model
final class ScriptMock {
    var id: UUID
    var title: String
    var author: String

    @Relationship(deleteRule: .cascade)
    var pages: [ScriptPageMock]

    init(
        title: String,
        author: String,
        pages: [ScriptPageMock] = []
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.pages = pages
    }
}
