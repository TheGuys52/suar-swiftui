import Observation
import SwiftUI

@MainActor
@Observable
public final class ScriptPageCoordinator: CoordinatorProtocol {
    public var router: Router
    public let viewModel: ScriptPageViewModel

    public init(router: Router, scriptId: UUID) {
        self.router = router
        self.viewModel = ScriptPageViewModel(scriptId: scriptId)
        configureBindings()
    }

    @ViewBuilder
    public func start() -> some View {
        @Bindable var router = router
        @Bindable var coordinator = self
        ScriptPageView(viewModel: viewModel)
    }

    private func configureBindings() {
        viewModel.onBack = { [weak self] in
            self?.router.pop()
        }
    }
}
