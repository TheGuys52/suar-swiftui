//
//  AppRoute.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import Foundation

public enum AppRoute: Hashable, Identifiable {
    case home
    case library
    case reader(scriptId: UUID)
    
    public var id: String {
        switch self {
        case .home:
            return "home"
        case .library:
            return "library"
        case .reader(let scriptId):
            return "reader-\(scriptId.uuidString)"
        }
    }
}
