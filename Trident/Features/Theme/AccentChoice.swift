//
//  AccentChoice.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-18.
//

import SwiftUI

enum AccentChoice: String, CaseIterable, Identifiable, Codable, Sendable {
  case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, gray
  var id: String { rawValue }

  var uiColor: UIColor {
    switch self {
    case .red: return .systemRed
    case .orange: return .systemOrange
    case .yellow: return .systemYellow
    case .green: return .systemGreen
    case .mint: return .systemMint
    case .teal: return .systemTeal
    case .cyan: return .systemCyan
    case .blue: return .systemBlue
    case .indigo: return .systemIndigo
    case .purple: return UIColor(.twitchPurple)
    case .pink: return .systemPink
    case .brown: return .systemBrown
    case .gray: return .systemGray
    }
  }

  var color: Color { Color(uiColor) }
}

extension EnvironmentValues {
  @Entry var accent: AccentChoice = .purple
}
