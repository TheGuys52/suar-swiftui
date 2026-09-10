//
//  ThumbnailService.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import Foundation
import PDFKit
import SwiftUI
import UIKit

public final class ThumbnailService: ThumbnailServiceProtocol {
    public init() {}

    public func generateThumbnail(from fileURL: URL) async -> Data? {
        let ext = fileURL.pathExtension.lowercased()

        if ext == "docx" || ext == "doc" {
            return nil
        }

        if let pdfDocument = PDFDocument(url: fileURL),
           let pdfPage = pdfDocument.page(at: 0) {
            let thumbnail = pdfPage.thumbnail(of: CGSize(width: 600, height: 360), for: .mediaBox)
            return thumbnail.pngData()
        }

        if let image = UIImage(contentsOfFile: fileURL.path) {
            return image.pngData()
        }

        return nil
    }
}
