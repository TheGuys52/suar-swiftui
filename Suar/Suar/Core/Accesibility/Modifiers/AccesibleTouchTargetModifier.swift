//
//  AccesibleTouchTargetModifier.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 25/08/26.
//

import SwiftUI

public struct AccessibleTouchTargetModifier: ViewModifier {
    // TODO: [@Team-Accessibility] Atur default minimum frame size (44x44 pt sesuai Apple HIG)[cite: 1]
    public let minDimension: CGFloat
    
    public init(minDimension: CGFloat = 44) {
        self.minDimension = minDimension
    }
    
    public func body(content: Content) -> some View {
        content
            .frame(minWidth: minDimension, minHeight: minDimension)
            .contentShape(Rectangle())
    }
}

public extension View {
    func accessibleTouchTarget(minDimension: CGFloat = 44) -> some View {
        modifier(AccessibleTouchTargetModifier(minDimension: minDimension))
    }
}
