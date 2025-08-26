//
//  ScaleButtonStyle.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-22.
//

import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.85 : 1.0) // scale down on press
      .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == ScaleButtonStyle {
  static func scale() -> Self {
    ScaleButtonStyle()
  }
}
