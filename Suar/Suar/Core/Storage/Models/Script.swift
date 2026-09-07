//
//  Script.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import Foundation
import SwiftData

@Model
public final class Script {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var createdAt: Date
    public var lastAccessedAt: Date
    public var lastReadPage: Int
    public var pageCount: Int
    public var sourceFileName: String
    @Attribute(.externalStorage) public var thumbnailData: Data?
    
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
        thumbnailData: Data? = nil,
        pages: [ScriptPage] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.lastReadPage = lastReadPage
        self.pageCount = pageCount
        self.sourceFileName = sourceFileName
        self.thumbnailData = thumbnailData
        self.pages = pages
    }
}
