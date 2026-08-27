//
//  Router.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 24/08/26.
//

import Observation
import SwiftUI

@Observable
public final class Router {
    public var path = NavigationPath()
    public var presentedSheet: AppRoute?
    
    public init() {}
    
    public func push(_ route: AppRoute) {
        path.append(route)
    }
    
    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    public func popToRoot() {
        path = NavigationPath()
    }
    
    public func presentSheet(_ route: AppRoute) {
        presentedSheet = route
    }
    
    public func dismissSheet() {
        presentedSheet = nil
    }
}
