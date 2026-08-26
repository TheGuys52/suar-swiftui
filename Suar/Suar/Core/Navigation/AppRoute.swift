//
//  AppRoute.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import Foundation

public enum AppRoute: Hashable, Identifiable {
    case home
    // TODO: [@Team-Nav] Daftarkan rute navigasi fitur lainnya (library, ingestion, reader(scriptId: UUID))
    
    public var id: String {
        switch self {
        case .home:
            return "home"
        }
    }
}

// TODO: [@Team-All] Tambahkan case rute baru di enum ini saat membuat fitur baru[cite: 2].
// Pastikan parameter yang dikirim conform ke protocol `Hashable`[cite: 2].
