//
//  AppCoordinator.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 24/08/26.
//

import Observation
import SwiftUI

private enum AppFlow {
    case onboarding
    case main
}

@MainActor
@Observable
public final class AppCoordinator: CoordinatorProtocol {
    public var router: Router
    private let homeCoordinator: HomeCoordinator
    private let onboardingCoordinator: OnboardingCoordinator
    private var flow: AppFlow = .onboarding

    public init(router: Router = Router()) {
        self.router = router
        self.homeCoordinator = HomeCoordinator(router: router)
        self.onboardingCoordinator = OnboardingCoordinator(router: router)
        configureBindings()
    }

    @ViewBuilder
    public func start() -> some View {
        switch flow {
        case .onboarding:
            onboardingCoordinator.start()
        case .main:
            mainFlow()
        }
    }

    @ViewBuilder
    private func mainFlow() -> some View {
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
                    case .reader(let scriptId):
                        ScriptPageCoordinator(router: router, scriptId: scriptId).start()
                    }
                }
        }
    }

    private func configureBindings() {
        onboardingCoordinator.onCompleted = { [weak self] in
            self?.showMainFlow()
        }
    }

    private func showMainFlow() {
        router.popToRoot()
        flow = .main
    }
}
