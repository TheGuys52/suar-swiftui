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
    @State private var coordinator: AppCoordinator = AppCoordinator()
    
    // MARK: - SwiftData Container Setup
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Script.self,
            ScriptPage.self,
            ScriptBlock.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }()
    
    init() {
        // TODO: [@Team-All] Panggil DIContainer.shared.configure(modelContext:) menggunakan sharedModelContainer.mainContext[cite: 2]
        DIContainer.shared.configure(modelContext: sharedModelContainer.mainContext)
    }
    
    var body: some Scene {
        WindowGroup {
            coordinator.start()
        }
        .modelContainer(sharedModelContainer)
    }
}
