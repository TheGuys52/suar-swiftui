//
//  OCRError.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 30/08/26.
//

import Foundation

public enum OCRError: LocalizedError {
    case fileAccessDenied
    case unsupportedFormat
    case emptyPageText
    case failedToRenderImage
    
    public var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            return "Tidak dapat mengakses izin berkas PDF."
        case .unsupportedFormat:
            return "Berkas tidak didukung atau rusak."
        case .emptyPageText:
            return "Teks tidak ditemukan pada halaman naskah."
        case .failedToRenderImage:
            return "Gagal me-render gambar dari halaman PDF."
        }
    }
}
