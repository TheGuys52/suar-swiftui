//
//  AllScriptList.swift
//  Suar
//
//  Created by Ivan Putra Pratama on 26/08/26.
//

import SwiftUI

struct AllScriptList: View {
    let scripts: [Script]
    var onSelectScript: ((Script) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if scripts.isEmpty {
                EmptyScriptListPlaceholder()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(scripts, id: \.id) { script in
                        ScriptRowView(
                            title: script.title,
                            subtitle: script.sourceFileName
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectScript?(script)
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
            // HIG menyarankan ikon SF Symbol yang netral dan ukuran sedang/besar
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
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Divider()
        }
    }
}

#Preview {
        AllScriptList(scripts: [])
}
