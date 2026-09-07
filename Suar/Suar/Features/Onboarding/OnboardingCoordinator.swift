//
//  OnboardingCoordinator.swift
//  Suar
//
//  Created by Gogo Figo on 02/09/26.
//
import Observation
import SwiftUI

@MainActor
@Observable
public final class OnboardingCoordinator: CoordinatorProtocol {
    public var router: Router
    public let viewModel: OnboardingViewModel
    public var onCompleted: (() -> Void)?

    public init(router: Router) {
        self.router = router
        self.viewModel = OnboardingViewModel()
        configureBindings()
    }

    @ViewBuilder
    public func start() -> some View {
        OnboardingView(viewModel: viewModel)
    }

    private func configureBindings() {
        viewModel.onFinish = { [weak self] in
            self?.onCompleted?()
        }
    }
}
