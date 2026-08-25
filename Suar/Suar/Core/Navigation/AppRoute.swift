//
//  AppRoute.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import Foundation

public enum AppRoute: Hashable, Identifiable {
    case home
    case library
    case ingestion
    case reader(scriptId: UUID)
    
    public var id: String {
        switch self {
        case .home:
            return "home"
        case .library:
            return "library"
        case .ingestion:
            return "ingestion"
        case .reader(let scriptId):
            return "reader_\(scriptId.uuidString)"
        }
    }
}

// TODO: [@Team-All] Tambahkan case rute baru di enum ini saat membuat fitur baru[cite: 2].
// Pastikan parameter yang dikirim conform ke protocol `Hashable`[cite: 2].
