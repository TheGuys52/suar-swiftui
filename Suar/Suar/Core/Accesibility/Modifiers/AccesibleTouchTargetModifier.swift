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
        // TODO: [@Team-Accessibility] Bungkus content dengan frame minWidth & minHeight
        // serta tambahkan contentShape(Rectangle()) untuk memastikan seluruh area 44pt responsif terhadap ketukan
        content
    }
}

public extension View {
    func accessibleTouchTarget(minDimension: CGFloat = 44) -> some View {
        modifier(AccessibleTouchTargetModifier(minDimension: minDimension))
    }
}
