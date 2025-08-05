//
//  Color.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

import SwiftUI

extension Color {
    func toUIColor() -> UIColor {
        if let components = cgColor?.components {
            return UIColor(displayP3Red: components[0], green: components[1], blue: components[2], alpha: components[3])
        } else {
            return UIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        }
    }

    func toRGB() -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        if let components = cgColor?.components {
            return (red: components[0], green: components[1], blue: components[2])
        } else {
            return (red: 0.0, green: 0.0, blue: 0.0)
        }
    }

    func toColorCode() -> String {
        if let components = cgColor?.components {
            let rgb: [CGFloat] = [components[0], components[1], components[2]]
            return rgb.reduce("") { res, value in
                let intval = Int(round(value * 255))
                return res + (NSString(format: "%02X", intval) as String)
            }
        } else {
            return ""
        }
    }

    init(hex: String) {
        let v = Int("000000" + hex.trimmingCharacters(in: ["#"]), radix: 16) ?? 0
        let r = CGFloat(v / Int(powf(256, 2)) % 256) / 255
        let g = CGFloat(v / Int(powf(256, 1)) % 256) / 255
        let b = CGFloat(v / Int(powf(256, 0)) % 256) / 255
        self.init(red: r, green: g, blue: b)
    }
}
