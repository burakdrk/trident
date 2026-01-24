import SwiftUI

private struct ApplyThemeModifier: ViewModifier {
  @Environment(\.themeManager) private var themeManager
  @Environment(\.colorScheme) private var systemScheme

  func body(content: Content) -> some View {
    content
      .environment(\.theme, themeManager.theme.palette(for: systemScheme))
      .environment(\.accent, themeManager.accent)
      .tint(themeManager.accent.color)
      .preferredColorScheme(themeManager.theme.preferredColorScheme)
  }
}

extension View {
  func applyTheme() -> some View {
    modifier(ApplyThemeModifier())
  }
}
