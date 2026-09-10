//
//  ScriptSorter.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import Foundation
import SwiftData

public final class ScriptSorter: ScriptSorterProtocol {
    public init() {}

    public func group(scripts: [Script], by option: ScriptSortOption) -> [GroupedScript] {
        switch option {
        case .alphabetical:
            return GroupedScript.groupByLetter(scripts: scripts)
        case .newestFirst:
            return GroupedScript.groupByMonth(scripts: scripts, ascending: false)
        case .oldestFirst:
            return GroupedScript.groupByMonth(scripts: scripts, ascending: true)
        }
    }
}
