//
//  ThemedModifiers.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-18.
//

import SwiftUI

struct ThemedBackground: ViewModifier {
  @Environment(\.theme) private var theme
  var ignoresSafeArea: Bool = true

  func body(content: Content) -> some View {
    content.background(theme.bg.ignoresSafeArea(ignoresSafeArea ? .all : []))
  }
}

struct ThemedCard: ViewModifier {
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View {
    content
      .background(theme.bgElev)
  }
}

struct ThemedPrimaryText: ViewModifier {
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View { content.foregroundStyle(theme.fg) }
}

struct ThemedSecondaryText: ViewModifier {
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View { content.foregroundStyle(theme.fgSecondary) }
}

struct AccentForeground: ViewModifier {
  @Environment(\.accent) private var accent

  func body(content: Content) -> some View { content.foregroundStyle(accent.color) }
}

extension View {
  func themedBackground(ignoresSafeArea: Bool = true) -> some View {
    modifier(ThemedBackground(ignoresSafeArea: ignoresSafeArea))
  }

  func themedCard() -> some View { modifier(ThemedCard()) }
  func themedPrimaryText() -> some View { modifier(ThemedPrimaryText()) }
  func themedSecondaryText() -> some View { modifier(ThemedSecondaryText()) }
  func accentForeground() -> some View { modifier(AccentForeground()) }
}

/// A divider that respects the palette
struct ThemedDivider: View {
  @Environment(\.theme) private var theme

  var body: some View { Divider().overlay(theme.separator) }
}
