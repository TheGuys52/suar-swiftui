//
//  AllScriptsSection.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import SwiftUI

struct AllScriptsSection: View {
    let scripts: [Script]
    var onSelectScript: ((Script) -> Void)?
    @State private var sortOption: ScriptSortOption = .newestFirst

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Semua Naskah")
                    .font(.custom("Georgia", size: 22, relativeTo: .title2))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("Semua Naskah")

                Menu {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(ScriptSortOption.allCases, id: \.self) { option in
                            Label(option.title, systemImage: option.icon)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 19, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .background(.ultraThickMaterial)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .glassEffect()
            }
            .padding(.horizontal)

            AllScriptList(
                groupedScripts: GroupedScript.groupByMonth(scripts: scripts, ascending: sortOption == .oldestFirst),
                onSelectScript: onSelectScript
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Empty") {
    AllScriptsSection(scripts: [])
}

#Preview("With Data") {
    AllScriptsSection(scripts: [
        Script(title: "Ruang Tunggu - Bagian 1", createdAt: Date(), pageCount: 24),
        Script(title: "Ruang Tunggu - Bagian 2", createdAt: Date().addingTimeInterval(-86400), pageCount: 18)
    ])
}
