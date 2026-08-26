////
////  HomeViewModel.swift
////  Suar
////
////  Created by DIMAS DAFFA ERNANDA on 25/08/26.
////
//
// import Foundation
//
// @Observable
// @MainActor
// public final class HomeViewModel {
//    // MARK: - State
//    public var recentScripts: [Script] = []
//    public var isLoading: Bool = false
//    public var errorMessage: String?
//    
//    // MARK: - Navigation Callbacks
//    public var onSelectScript: ((UUID) -> Void)?
//    public var onImportTapped: (() -> Void)?
//    public var onLibraryTapped: (() -> Void)?
//    
//    // MARK: - Dependencies
//    private let repository: ScriptRepositoryProtocol?
//    
//    public init(repository: ScriptRepositoryProtocol? = DIContainer.shared.scriptRepository) {
//        self.repository = repository
//    }
//    
//    // MARK: - Intents
//    public func fetchRecentScripts() async {
//        // TODO: [@Team-UI / Issue #5] Panggil repository?.fetchRecentScripts(limit: 5)
//        // TODO: Update state isLoading dan recentScripts dengan handling do-catch
//    }
//    
//    public func didTapScript(id: UUID) {
//        onSelectScript?(id)
//    }
//    
//    public func didTapImport() {
//        onImportTapped?()
//    }
//    
//    public func didTapLibrary() {
//        onLibraryTapped?()
//    }
// }
