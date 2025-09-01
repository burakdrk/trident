import SwiftUI

enum AccentChoice: String, CaseIterable, Identifiable, Codable, Sendable {
  case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, gray
  var id: String { rawValue }

  var color: Color {
    switch self {
    case .red: .red
    case .orange: .orange
    case .yellow: .yellow
    case .green: .green
    case .mint: .mint
    case .teal: .teal
    case .cyan: .cyan
    case .blue: .blue
    case .indigo: .indigo
    case .purple: .twitchPurple
    case .pink: .pink
    case .brown: .brown
    case .gray: .gray
    }
  }

  var uiColor: UIColor { UIColor(color) }
}

extension EnvironmentValues {
  @Entry var accent: AccentChoice = .purple
}
