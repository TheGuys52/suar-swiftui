//
//  GroupedScript.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import Foundation
import SwiftData

public struct GroupedScript: Identifiable, Hashable {
    public let id: String
    public let label: String
    public let scripts: [Script]

    public init(id: String, label: String, scripts: [Script]) {
        self.id = id
        self.label = label
        self.scripts = scripts
    }

    // ponytail: grouping logic lives here, upgrade to ScriptSorter service if testability needed
    public static func groupByMonth(scripts: [Script], ascending: Bool) -> [GroupedScript] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let sorted = scripts.sorted { $0.createdAt > $1.createdAt }
        let grouped = Dictionary(grouping: sorted) { $0.createdAt }
        let order = grouped.keys.sorted { date1, date2 in
            ascending ? date1 < date2 : date1 > date2
        }
        return order.map { date in
            GroupedScript(
                id: formatter.string(from: date),
                label: formatter.string(from: date).uppercased(),
                scripts: grouped[date] ?? []
            )
        }
    }

    public static func groupByLetter(scripts: [Script]) -> [GroupedScript] {
        let sorted = scripts.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
        return [GroupedScript(id: "all", label: "", scripts: sorted)]
    }
}
