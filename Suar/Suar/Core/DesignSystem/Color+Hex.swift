//
//  Color+Hex.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import SwiftUI

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, redVal, greenVal, blueVal: UInt64
        switch hex.count {
        case 3:
            (alpha, redVal, greenVal, blueVal) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (alpha, redVal, greenVal, blueVal) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (alpha, redVal, greenVal, blueVal) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, redVal, greenVal, blueVal) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(redVal) / 255,
            green: Double(greenVal) / 255,
            blue: Double(blueVal) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
