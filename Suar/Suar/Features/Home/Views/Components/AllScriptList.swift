//
//  AllScriptList.swift
//  Suar
//
//  Created by Ivan Putra Pratama on 26/08/26.
//

import SwiftUI

struct GroupedScript: Identifiable {
    let id: String
    let label: String
    let scripts: [Script]
}

struct AllScriptList: View {
    let groupedScripts: [GroupedScript]
    var onSelectScript: ((Script) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if groupedScripts.isEmpty {
                EmptyScriptListPlaceholder()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(groupedScripts) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            if !section.label.isEmpty {
                                Text(section.label)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.themeTypo)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 8)
                            }

                            ForEach(section.scripts, id: \.id) { script in
                                ScriptRowView(
                                    title: script.title,
                                    createdAt: script.createdAt,
                                    pageCount: script.pageCount
                                )
                                .padding(.leading, 8)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onSelectScript?(script)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct EmptyScriptListPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(Color.themeRed)

            VStack(spacing: 4) {
                Text("Naskah Masih Kosong")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Daftar naskah kamu belum tersedia.\nTekan tombol + untuk mengimpor file PDF naskahmu.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ScriptRowView: View {
    let title: String
    let createdAt: Date
    let pageCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)

            Text(subtitleText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()
        }
    }

    private var subtitleText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "id_ID")
        dateFormatter.dateFormat = "dd MMMM"
        let formattedDate = dateFormatter.string(from: createdAt)
        let pageText = pageCount > 0 ? "\(pageCount) Halaman" : "Belum ada halaman"
        return "\(formattedDate)   \(pageText)"
    }
}

#Preview("Empty") {
    AllScriptList(groupedScripts: [])
}

#Preview("With Data") {
    let sep2026 = Date()
    let aug2026 = Calendar.current.date(byAdding: .day, value: -30, to: sep2026)!
    let sampleData: [GroupedScript] = [
        GroupedScript(
            id: "1",
            label: "SEPTEMBER 2026",
            scripts: [
                Script(title: "Ruang Tunggu - Bagian 1", createdAt: sep2026, lastReadPage: 1, pageCount: 24),
                Script(title: "Ruang Tunggu - Bagian 2", createdAt: sep2026, lastReadPage: 1, pageCount: 18)
            ]
        ),
        GroupedScript(
            id: "2",
            label: "",
            scripts: [
                Script(title: "Naskah Lama", createdAt: aug2026, lastReadPage: 1, pageCount: 5)
            ]
        )
    ]
    AllScriptList(groupedScripts: sampleData)
}
