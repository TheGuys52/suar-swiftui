//
//  ScriptSeederServiceProtocol.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import Foundation

public protocol ScriptSeederServiceProtocol: Sendable {
    func seedIfNeeded() async
}
