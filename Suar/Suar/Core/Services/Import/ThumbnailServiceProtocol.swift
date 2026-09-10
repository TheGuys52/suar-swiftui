//
//  ThumbnailServiceProtocol.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import Foundation

public protocol ThumbnailServiceProtocol: Sendable {
    func generateThumbnail(from fileURL: URL) async -> Data?
}
