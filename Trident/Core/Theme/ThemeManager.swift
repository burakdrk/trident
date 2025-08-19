//
//  ThemeManager.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-18.
//

import SwiftUI

@MainActor
@Observable
final class ThemeManager {
  var theme: ThemeChoice
  var accent: AccentChoice

  @ObservationIgnored private let defaults = UserDefaults.standard
  @ObservationIgnored private let themeKey = "theme.choice.v1"
  @ObservationIgnored private let accentKey = "theme.accentChoice.v1"

  init(initialTheme: ThemeChoice = .system, initialAccent: AccentChoice = .red) {
    if let raw = defaults.string(forKey: themeKey), let t = ThemeChoice(rawValue: raw) {
      theme = t
    } else {
      theme = initialTheme
    }

    if let raw = defaults.string(forKey: accentKey), let a = AccentChoice(rawValue: raw) {
      accent = a
    } else {
      accent = initialAccent
    }
  }

  func setTheme(_ new: ThemeChoice) {
    theme = new
    defaults.set(new.rawValue, forKey: themeKey)
  }

  func setAccent(_ new: AccentChoice) {
    accent = new
    defaults.set(new.rawValue, forKey: accentKey)
  }
}
