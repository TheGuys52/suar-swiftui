//
//  CoordinatorProtocol.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import SwiftUI

@MainActor
public protocol CoordinatorProtocol: AnyObject {
    var router: Router { get set }
    
    associatedtype ContentView: View
    @ViewBuilder func start() -> ContentView
}

// TODO: [@Feature-Leads] Setiap fitur (Home, Library, Ingestion, Reader) wajib memiliki
// koordinatornya sendiri yang conform ke protocol ini (contoh: `HomeCoordinator`, `ReaderCoordinator`)
