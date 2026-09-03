//
//  ScriptParserServiceProtocol.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import Foundation

public protocol ScriptParserServiceProtocol: Sendable {
    func parseScript(
        rawPagesText: [Int: String],
        scriptTitle: String,
        sourceFileName: String,
        onProgress: ((_ currentPage: Int, _ totalPages: Int) -> Void)?
    ) async throws -> Script
}
