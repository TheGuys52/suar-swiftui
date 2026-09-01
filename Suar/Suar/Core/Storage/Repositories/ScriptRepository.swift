//
//  ScriptRepository.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 30/08/26.
//

import Foundation
import SwiftData

public actor ScriptRepository: ScriptRepositoryProtocol {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch Operations

    /// Mengambil seluruh naskah yang tersimpan, diurutkan dari yang terbaru diakses.
    public nonisolated func fetchAllScripts() async throws -> [Script] {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    let descriptor = FetchDescriptor<Script>(
                        sortBy: [SortDescriptor(\.lastAccessedAt, order: .reverse)]
                    )
                    let scripts = try modelContext.fetch(descriptor)
                    continuation.resume(returning: scripts)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Mengambil daftar naskah terakhir diakses sesuai limit, diurutkan dari yang terbaru.
    public nonisolated func fetchRecentScripts(limit: Int) async throws -> [Script] {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    var descriptor = FetchDescriptor<Script>(
                        sortBy: [SortDescriptor(\.lastAccessedAt, order: .reverse)]
                    )
                    descriptor.fetchLimit = limit
                    let scripts = try modelContext.fetch(descriptor)
                    continuation.resume(returning: scripts)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Mencari naskah berdasarkan pencocokan judul (case-insensitive).
    public nonisolated func searchScripts(query: String) async throws -> [Script] {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    let lowercasedQuery = query.lowercased()
                    let descriptor = FetchDescriptor<Script>(
                        sortBy: [SortDescriptor(\.lastAccessedAt, order: .reverse)]
                    )
                    let allScripts = try modelContext.fetch(descriptor)
                    let filtered = allScripts.filter { $0.title.lowercased().contains(lowercasedQuery) }
                    continuation.resume(returning: filtered)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Mengambil satu naskah lengkap beserta halaman dan blok dialog berdasarkan ID.
    public nonisolated func fetchScript(by id: UUID) async throws -> Script? {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    let descriptor = FetchDescriptor<Script>(
                        predicate: #Predicate { $0.id == id }
                    )
                    let scripts = try modelContext.fetch(descriptor)
                    continuation.resume(returning: scripts.first)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - CRUD Operations

    /// Menyimpan naskah baru hasil impor OCR/Parser ke database SwiftData.
    public nonisolated func save(script: Script) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task { @MainActor in
                do {
                    modelContext.insert(script)
                    try modelContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Memperbarui halaman terakhir yang dibaca dan timestamp akses.
    public nonisolated func updateLastReadPage(scriptId: UUID, pageNumber: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task { @MainActor in
                do {
                    let descriptor = FetchDescriptor<Script>(
                        predicate: #Predicate { $0.id == scriptId }
                    )
                    guard let script = try modelContext.fetch(descriptor).first else {
                        continuation.resume()
                        return
                    }
                    script.lastReadPage = pageNumber
                    script.lastAccessedAt = Date()
                    try modelContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Menghapus naskah beserta seluruh halaman dan blok dialog terkait (cascade delete).
    public nonisolated func delete(script: Script) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task { @MainActor in
                do {
                    modelContext.delete(script)
                    try modelContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
