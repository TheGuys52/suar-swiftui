import SwiftUI

struct AllScriptsSection: View {
    let scripts: [Script]
    var onSelectScript: ((Script) -> Void)?
    @State private var sortOption: SortOption = .newestFirst

    enum SortOption: String, CaseIterable {
        case newestFirst
        case oldestFirst
        case alphabetical

        var title: String {
            switch self {
            case .newestFirst:
                return "Terbaru"
            case .oldestFirst:
                return "Terlama"
            case .alphabetical:
                return "Abjad (A-Z)"
            }
        }

        var icon: String {
            switch self {
            case .newestFirst:
                return "clock.arrow.circlepath"
            case .oldestFirst:
                return "clock"
            case .alphabetical:
                return "textformat.abc"
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Semua Naskah")
//                    .bold()
                    .font(.custom("Georgia", size: 22, relativeTo: .title2))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(allScriptLabel)
                    
                Menu {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
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
                groupedScripts: groupedScripts,
                onSelectScript: onSelectScript
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var allScriptLabel: String {
        "Semua Naskah"
    }

    private var groupedScripts: [GroupedScript] {
        switch sortOption {
        case .alphabetical:
            return groupByLetter(scripts: scripts)
        case .newestFirst:
            return groupByMonth(scripts: scripts, ascending: false)
        case .oldestFirst:
            return groupByMonth(scripts: scripts, ascending: true)
        }
    }

    private func groupByMonth(scripts: [Script], ascending: Bool) -> [GroupedScript] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let sorted = scripts.sorted { $0.createdAt > $1.createdAt }
        let grouped = Dictionary(grouping: sorted) { script in
            formatter.string(from: script.createdAt)
        }

        let order = grouped.keys.sorted { key1, key2 in
            let date1 = formatter.date(from: key1) ?? .distantPast
            let date2 = formatter.date(from: key2) ?? .distantPast
            return ascending ? date1 < date2 : date1 > date2
        }

        return order.map { label in
            GroupedScript(
                id: label,
                label: label.uppercased(),
                scripts: grouped[label] ?? []
            )
        }
    }

    private func groupByLetter(scripts: [Script]) -> [GroupedScript] {
        let sorted = scripts.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
        return [GroupedScript(id: "all", label: "", scripts: sorted)]
    }
}

#Preview {
    AllScriptsSection(scripts: [])
}
