import SwiftUI

struct ThemePalette: Sendable {
  let bg: Color
  let bgElev: Color
  let fg: Color
  let fgSecondary: Color
  let separator: Color
}

// MARK: - Light Theme

extension ThemePalette {
  /// Regular light theme.
  static let light = Self(
    bg: Color(.systemBackground),
    bgElev: Color(.secondarySystemBackground),
    fg: Color(.label),
    fgSecondary: Color(.secondaryLabel),
    separator: Color(.separator)
  )
}

// MARK: - Dark Theme

extension ThemePalette {
  /// Dark gray (not pure black).
  static let dark = Self(
    bg: Color(.secondarySystemBackground),
    bgElev: Color(UIColor(hex: "#101011") ?? .black),
    fg: Color(.label),
    fgSecondary: Color(.secondaryLabel),
    separator: Color(.separator)
  )
}

// MARK: - Black Theme

extension ThemePalette {
  /// True black for OLED.
  static let black = Self(
    bg: Color(.systemBackground),
    bgElev: Color(.secondarySystemBackground),
    fg: Color(.label),
    fgSecondary: Color(.secondaryLabel),
    separator: Color(.separator)
  )
}

extension EnvironmentValues {
  @Entry var theme: ThemePalette = .dark
}
