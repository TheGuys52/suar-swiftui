//
//  ScriptBlockType.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import Foundation

public enum ScriptBlockType: String, Codable, CaseIterable, Sendable {
    case sceneHeader
    case characterName
    case dialogue
    case stageDirection
    case narration
}

// TODO: [@Team-All] Tambahkan case baru di sini jika ke depan ada tipe blok baru
// seperti parenthetical, transition, atau note tambahan.
