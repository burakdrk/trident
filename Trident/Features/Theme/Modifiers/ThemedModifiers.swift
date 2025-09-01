import SwiftUI

private struct ThemedBackground: ViewModifier {
  @Environment(\.theme) private var theme
  var ignoresSafeArea: Bool = true

  func body(content: Content) -> some View {
    content.background(Color(theme.bg).ignoresSafeArea(ignoresSafeArea ? .all : []))
  }
}

private struct ThemedAppBackground: ViewModifier {
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View {
    ZStack {
      Rectangle()
        .foregroundColor(Color(theme.bg))
        .edgesIgnoringSafeArea(.all)

      content
    }
  }
}

private struct ThemedCard: ViewModifier {
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View {
    content
      .background(Color(theme.bgElev))
  }
}

private struct ThemedForeground: ViewModifier {
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View { content.foregroundStyle(Color(theme.fg)) }
}

private struct ThemedSecondaryForeground: ViewModifier {
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View { content.foregroundStyle(Color(theme.fgSecondary)) }
}

private struct AccentForeground: ViewModifier {
  @Environment(\.accent) private var accent

  func body(content: Content) -> some View { content.foregroundStyle(accent.color) }
}

extension View {
  func themedBackground(ignoresSafeArea: Bool = true) -> some View {
    modifier(ThemedBackground(ignoresSafeArea: ignoresSafeArea))
  }

  func themedAppBackground() -> some View { modifier(ThemedAppBackground()) }
  func themedCard() -> some View { modifier(ThemedCard()) }
  func themedForeground() -> some View { modifier(ThemedForeground()) }
  func themedSecondaryForeground() -> some View { modifier(ThemedSecondaryForeground()) }
  func accentForeground() -> some View { modifier(AccentForeground()) }
}
