//
//  ScriptImportPipelineServiceProtocol.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import Foundation
import SwiftData

public protocol ScriptImportPipelineServiceProtocol: Sendable {
    var onPhaseChange: ((ProcessingPhase) -> Void)? { get set }
    var onScriptReady: ((Script) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }

    func processFile(at url: URL, title: String) async
    func cancel()
}
