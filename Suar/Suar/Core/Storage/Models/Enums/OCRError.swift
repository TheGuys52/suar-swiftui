//
//  OCRError.swift
//  Suar
//
//  Created by Adiat Rahman on 27/08/26.
//

import Foundation

public enum OCRError: LocalizedError {
    case cannotOpenDocument
    case cannotLoadImage
    case cannotConvertImage
    
    public var errorDescription: String? {
        switch self {
        case .cannotOpenDocument:
            return "Cannot open document"
        case .cannotLoadImage:
            return "Cannot load image"
        case .cannotConvertImage:
            return "Cannot convert image for OCR"
        }
    }
}
