import SwiftUI

enum ThemeChoice: String, CaseIterable, Identifiable, Codable, Sendable {
  case system, light, dark, black
  var id: String { rawValue }

  var preferredColorScheme: ColorScheme? {
    switch self {
    case .system: nil
    case .light: .light
    case .dark, .black: .dark
    }
  }

  func palette(for systemScheme: ColorScheme) -> ThemePalette {
    switch self {
    case .system: systemScheme == .dark ? .dark : .light
    case .light: .light
    case .dark: .dark
    case .black: .black
    }
  }
}
