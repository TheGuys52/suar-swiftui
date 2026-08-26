//
//  Router.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 24/08/26.
//

import SwiftUI

@Observable
public final class Router {
    public var path: NavigationPath = NavigationPath()
    public var presentedSheet: AppRoute?
    // TODO: [@Team-Nav] Tambahkan state modal presentation lainnya jika dibutuhkan
    
    public init() {}
    
    // TODO: [@Team-Nav] Implementasikan method helper navigasi:
    // - push(_ route: AppRoute)
    // - pop() / popToRoot()
    // - presentSheet(_ route: AppRoute) / dismissSheet()
}
