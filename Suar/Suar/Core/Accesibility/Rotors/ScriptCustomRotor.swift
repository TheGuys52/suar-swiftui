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

// TODO: [@Team-Accessibility / Issue #4] Buat ViewModifier atau View Extension untuk Custom Rotor[cite: 1, 2].
// Gunakan API `.accessibilityRotor(_:entries:)` pada SwiftUI View[cite: 1]
// agar pengguna VoiceOver dapat beralih konteks pembacaan naskah secara granular[cite: 1].
