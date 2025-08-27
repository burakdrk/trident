import SwiftUI

private struct ThemedBackground: ViewModifier {
  @Environment(\.theme) private var theme
  var ignoresSafeArea: Bool = true

  func body(content: Content) -> some View {
    content.background(theme.bg.ignoresSafeArea(ignoresSafeArea ? .all : []))
  }
}

private struct ThemedCard: ViewModifier {
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View {
    content
      .background(theme.bgElev)
  }
}

private struct ThemedPrimaryText: ViewModifier {
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View { content.foregroundStyle(theme.fg) }
}

private struct ThemedSecondaryText: ViewModifier {
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View { content.foregroundStyle(theme.fgSecondary) }
}

private struct AccentForeground: ViewModifier {
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
