//
//  ScaleButtonStyle.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-09.
//

import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
  let scaleAmount: CGFloat
  let animationDuration: Double

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
      .animation(
        .easeInOut(duration: animationDuration),
        value: configuration.isPressed
      )
  }
}

extension ButtonStyle where Self == ScaleButtonStyle {
  static func scale(amount: CGFloat = 0.95, duration: Double = 0.1) -> ScaleButtonStyle {
    ScaleButtonStyle(scaleAmount: amount, animationDuration: duration)
  }
}
