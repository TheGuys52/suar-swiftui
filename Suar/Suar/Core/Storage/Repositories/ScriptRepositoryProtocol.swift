//
//  ScriptRepositoryProtocol.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import Foundation

public protocol ScriptRepositoryProtocol: Sendable {
    /// Mengambil seluruh naskah yang tersimpan, diurutkan dari yang terbaru diakses
    func fetchAllScripts() async throws -> [Script]
    
    /// Mengambil daftar naskah untuk seksi "Recent Scripts" pada Homepage
    /// - Parameter limit: Jumlah maksimal naskah yang diambil.
    func fetchRecentScripts(limit: Int) async throws -> [Script]
    
    /// Mencari naskah berdasarkan pencocokan judul[cite: 1].
    /// - Parameter query: Kata kunci pencarian judul naskah.
    func searchScripts(query: String) async throws -> [Script]
    
    /// Mengambil satu entitas naskah lengkap beserta halaman dan blok dialognya berdasarkan ID
    func fetchScript(by id: UUID) async throws -> Script?
    
    /// Menyimpan naskah baru hasil impor OCR/Parser ke database SwiftData
    func save(script: Script) async throws
    
    /// Memperbarui bookmark halaman terakhir yang dibaca pengguna
    func updateLastReadPage(scriptId: UUID, pageNumber: Int) async throws
    
    /// Menghapus naskah beserta seluruh halaman dan blok terkait (cascade)
    func delete(script: Script) async throws
}

// TODO: [@Team-Storage] Buat file `ScriptRepository.swift` yang mengimplementasikan protocol ini
// menggunakan `ModelContext` SwiftData dan jalankan operasinya di background actor.
