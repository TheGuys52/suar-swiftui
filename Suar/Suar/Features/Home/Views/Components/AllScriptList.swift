//
//  AllScriptList.swift
//  Suar
//
//  Created by Ivan Putra Pratama on 26/08/26.
//

import SwiftUI

struct AllScriptList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("August 2026")
                    .font(.headline)
                    .foregroundStyle(Color.themeRed)
                
                VStack(alignment: .leading, spacing: 12) {
                    ScriptRowView(title: "Kimigami to Kurogami")
                    ScriptRowView(title: "Pelangi Dimatamu")
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("July 2026")
                    .font(.headline)
                    .foregroundStyle(Color.themeRed)
                
                VStack(alignment: .leading, spacing: 12) {
                    ScriptRowView(title: "Cinta di Ambarawa")
                    ScriptRowView(title: "Thamrin nine dan Janjinya")
                }
            }
            
        }
        .padding(.horizontal)
    }
}

struct ScriptRowView: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
            
            Divider()
        }
    }
}

#Preview {
    ScrollView {
        AllScriptList()
    }
}
