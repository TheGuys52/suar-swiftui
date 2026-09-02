import Observation
import SwiftUI

@MainActor
@Observable
public final class HomeCoordinator: CoordinatorProtocol {
    public var router: Router
    public let viewModel: HomeViewModel
    public var isPresentingImportPicker = false
    
    public init(router: Router) {
        self.router = router
        self.viewModel = HomeViewModel()
        configureBindings()
    }
    
    @ViewBuilder
    public func start() -> some View {
        @Bindable var router = router
        @Bindable var coordinator = self
        NavigationStack {
            HomeView(
                viewModel: viewModel,
                isShowingFileImporter: $coordinator.isPresentingImportPicker
            )
        }
    }
    
    private func configureBindings() {
        viewModel.onImportTapped = { [weak self] in
            self?.isPresentingImportPicker = true
        }

        viewModel.onSelectScript = { [weak self] scriptId in
            self?.router.push(.reader(scriptId: scriptId))
        }

        viewModel.onLibraryTapped = { [weak self] in
            self?.router.push(.library)
        }

        viewModel.onOpenScriptReader = { [weak self] script in
            self?.openScriptReader(script: script)
        }
    }

    /// Navigasi ke halaman reader untuk script tertentu berdasarkan ID.
    public func openScriptReader(script: Script) {
        router.push(.reader(scriptId: script.id))
    }
}
