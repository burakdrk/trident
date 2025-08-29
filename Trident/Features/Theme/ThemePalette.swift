import SwiftUI

struct ThemePalette: Sendable {
  let bg: UIColor
  let bgElev: UIColor
  let fg: UIColor
  let fgSecondary: UIColor
  let separator: UIColor
}

// MARK: - Light Theme

extension ThemePalette {
  /// Regular light theme.
  static let light = Self(
    bg: .systemBackground,
    bgElev: .secondarySystemBackground,
    fg: .label,
    fgSecondary: .secondaryLabel,
    separator: .separator
  )
}

// MARK: - Dark Theme

extension ThemePalette {
  /// Dark gray (not pure black).
  static let dark = Self(
    bg: .secondarySystemBackground,
    bgElev: UIColor(hex: "#101011") ?? .black,
    fg: .label,
    fgSecondary: .secondaryLabel,
    separator: .separator
  )
}

// MARK: - Black Theme

extension ThemePalette {
  /// True black for OLED.
  static let black = Self(
    bg: .systemBackground,
    bgElev: .secondarySystemBackground,
    fg: .label,
    fgSecondary: .secondaryLabel,
    separator: .separator
  )
}

extension EnvironmentValues {
  @Entry var theme: ThemePalette = .dark
}
