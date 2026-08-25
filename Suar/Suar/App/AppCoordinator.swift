//
//  AppCoordinator.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 24/08/26.
//

import SwiftUI

@MainActor
@Observable
public final class AppCoordinator: CoordinatorProtocol {
    public var router: Router
    
    public init(router: Router = Router()) {
        self.router = router
    }
    
    @ViewBuilder
    public func start() -> some View {
        // TODO: [@Team-Nav] Setup NavigationStack(path:) menggunakan router.path[cite: 2]
        // TODO: [@Team-Nav] Tambahkan modifier .navigationDestination(for: AppRoute.self) dan modal sheet[cite: 2]
        // TODO: [@Team-UI] Hubungkan ke root view awal (HomeView)[cite: 1]
        Text("Suar Root Screen")
    }
}
