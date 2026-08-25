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
}
