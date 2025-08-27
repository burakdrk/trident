import SwiftUI

struct HideFloatingTabBarModifier: ViewModifier {
  @Environment(\.router) private var router

  var status: Bool

  func body(content: Content) -> some View {
    content
      .onChange(of: status, initial: true) { _, newValue in
        router.hideTabBar = newValue
      }
      .onDisappear {
        router.hideTabBar = false
      }
  }
}

extension View {
  func hideFloatingTabBar(_ status: Bool = true) -> some View {
    modifier(HideFloatingTabBarModifier(status: status))
  }
}
