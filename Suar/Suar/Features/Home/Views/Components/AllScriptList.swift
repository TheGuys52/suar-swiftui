//
//  AllScriptList.swift
//  Suar
//
//  Created by Ivan Putra Pratama on 26/08/26.
//

import SwiftUI

struct AllScriptList: View {
    let scripts: [Script]
    
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
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct EmptyScriptListPlaceholder: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title3)
                .foregroundStyle(Color.themeRed)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Belum ada naskah")
                    .font(.headline)
                    .bold()
                
                Text("Saat kamu mengimpor PDF, file-nya akan muncul di sini.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(.thinMaterial)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.themeRed.opacity(0.25), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
    ScrollView {
        AllScriptList(scripts: [])
    }
}
