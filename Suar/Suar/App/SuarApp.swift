//
//  SuarApp.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 24/08/26.
//

import SwiftData
import SwiftUI

@main
struct SuarApp: App {
    @State private var coordinator: AppCoordinator
    let sharedModelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            Script.self,
            ScriptPage.self,
            ScriptBlock.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.sharedModelContainer = container
            
            // 1. Konfigurasi DIContainer terlebih dahulu
            DIContainer.shared.configure(modelContext: container.mainContext)
            
            // 2. Buat instance AppCoordinator setelah DIContainer siap
            _coordinator = State(wrappedValue: AppCoordinator())
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            coordinator.start()
                .preferredColorScheme(.light)
                .environment(\.locale, Locale(identifier: "id-ID"))
        }
        .modelContainer(sharedModelContainer)
    }
}
