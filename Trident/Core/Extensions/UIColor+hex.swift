//
//  UIColor+hex.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-09.
//

import UIKit

public extension UIColor {
  convenience init?(hex: String) {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    if hex.hasPrefix("#") {
      let start = hex.index(hex.startIndex, offsetBy: 1)
      var hexColor = String(hex[start...])

      if hexColor.count == 6 {
        hexColor += "FF" // Default alpha value if not provided
      }

      if hexColor.count == 8 {
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
          red = CGFloat((hexNumber & 0xFF00_0000) >> 24) / 255
          green = CGFloat((hexNumber & 0x00FF_0000) >> 16) / 255
          blue = CGFloat((hexNumber & 0x0000_FF00) >> 8) / 255
          alpha = CGFloat(hexNumber & 0x0000_00FF) / 255

          self.init(red: red, green: green, blue: blue, alpha: alpha)
          return
        }
      }
    }

    return nil
  }
}
