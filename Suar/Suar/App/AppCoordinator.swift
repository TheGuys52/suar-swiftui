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
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .home:
                        HomeView()
                    }
                }
        }
    }
}
