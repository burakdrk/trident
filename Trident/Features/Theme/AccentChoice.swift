import SwiftUI

enum AccentChoice: String, CaseIterable, Identifiable, Codable, Sendable {
  case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, gray
  var id: String { rawValue }

  var uiColor: UIColor {
    switch self {
    case .red: .systemRed
    case .orange: .systemOrange
    case .yellow: .systemYellow
    case .green: .systemGreen
    case .mint: .systemMint
    case .teal: .systemTeal
    case .cyan: .systemCyan
    case .blue: .systemBlue
    case .indigo: .systemIndigo
    case .purple: UIColor(.twitchPurple)
    case .pink: .systemPink
    case .brown: .systemBrown
    case .gray: .systemGray
    }
  }

  var color: Color { Color(uiColor) }
}

extension EnvironmentValues {
  @Entry var accent: AccentChoice = .purple
}
