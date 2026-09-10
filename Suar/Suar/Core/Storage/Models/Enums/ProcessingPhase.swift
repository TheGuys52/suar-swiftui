//
//  ProcessingPhase.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import Foundation

public enum ProcessingPhase: Equatable {
    case idle
    case ocr
    case parsing(current: Int, total: Int)
    case saving
    case success(scriptId: UUID, scriptTitle: String)
    case error(message: String)

    public var isActive: Bool {
        switch self {
        case .idle, .success, .error:
            return false
        default:
            return true
        }
    }
}
