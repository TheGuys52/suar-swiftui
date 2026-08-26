////
////  HomeCoordinator.swift
////  Suar
////
////  Created by DIMAS DAFFA ERNANDA on 25/08/26.
////
//
// import SwiftUI
//
// @MainActor
// @Observable
// public final class HomeCoordinator: CoordinatorProtocol {
//    public var router: Router
//    
//    public init(router: Router) {
//        self.router = router
//    }
//    
//    @ViewBuilder
//    public func start() -> some View {
//        let viewModel = HomeViewModel()
//        
//        // Setup Navigation Callbacks ke Router
//        viewModel.onSelectScript = { [weak self] _ in
//            // TODO: [@Team-Nav] self?.router.push(.reader(scriptId: scriptId))[cite: 1, 2]
//        }
//        
//        viewModel.onImportTapped = { [weak self] in
//            // TODO: [@Team-Nav] self?.router.presentSheet(.ingestion)[cite: 1, 2]
//        }
//        
//        viewModel.onLibraryTapped = { [weak self] in
//            // TODO: [@Team-Nav] self?.router.push(.library)[cite: 1, 2]
//        }
//        
//        HomeView(viewModel: viewModel)
//    }
// }
