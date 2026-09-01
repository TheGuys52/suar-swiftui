//
//  ScriptCustomRotor.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import SwiftUI

public enum ScriptRotorType: String, CaseIterable, Identifiable {
    case scenes = "Adegan"
    case characters = "Tokoh"
    case cues = "Petunjuk Aksi"

    public var id: String { rawValue }
}

// MARK: - Usage
// The actual rotor implementations are declared in ScriptPageView.swift via
// .accessibilityRotor(_:entries:). Use ScriptRotorType cases as the rotor
// identifier keys.
