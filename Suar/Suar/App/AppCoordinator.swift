//
//  AppCoordinator.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 24/08/26.
//

import Observation
import SwiftUI

@MainActor
@Observable
public final class AppCoordinator: CoordinatorProtocol {
    public var router: Router
    private let homeCoordinator: HomeCoordinator
    
    public init(router: Router = Router()) {
        self.router = router
        self.homeCoordinator = HomeCoordinator(router: router)
    }
    
    @ViewBuilder
    public func start() -> some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            self.homeCoordinator.start()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .home:
                        self.homeCoordinator.start()
                    case .library:
                        VStack(spacing: 12) {
                            Text("Library")
                                .font(.title)
                                .bold()
                            Text("Feature ini belum dihubungkan ke layar khusus.")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    case .reader:
                        ScriptPageCoordinator(router: router).start()
                    }
                }
        }
    }
}
