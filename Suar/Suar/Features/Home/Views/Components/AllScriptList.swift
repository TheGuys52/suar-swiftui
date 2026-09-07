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
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 8)
                            }

                            ForEach(section.scripts, id: \.id) { script in
                                ScriptRowView(
                                    title: script.title,
                                    subtitle: script.pageCount > 0
                                        ? "\(script.pageCount) Halaman"
                                        : "Belum ada halaman"
                                )
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
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()
        }
    }
}

#Preview {
    AllScriptList(groupedScripts: [])
}
