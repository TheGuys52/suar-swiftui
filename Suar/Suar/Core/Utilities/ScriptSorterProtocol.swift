//
//  ScriptSorterProtocol.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import Foundation
import SwiftData

public enum ScriptSortOption: String, CaseIterable, Sendable {
    case newestFirst
    case oldestFirst
    case alphabetical

    public var title: String {
        switch self {
        case .newestFirst: return "Terbaru"
        case .oldestFirst: return "Terlama"
        case .alphabetical: return "Abjad (A-Z)"
        }
    }

    public var icon: String {
        switch self {
        case .newestFirst: return "clock.arrow.circlepath"
        case .oldestFirst: return "clock"
        case .alphabetical: return "textformat.abc"
        }
    }
}

public protocol ScriptSorterProtocol: Sendable {
    func group(scripts: [Script], by option: ScriptSortOption) -> [GroupedScript]
}
