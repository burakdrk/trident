import SwiftUI

private struct AuthBoundaryModifier: ViewModifier {
  @Environment(\.auth) private var auth

  func body(content: Content) -> some View {
    Group {
      switch auth.state.phase {
      case .loggedIn:
        content
          .transition(.opacity)
      case .loggedOut:
        AuthBoundaryView()
          .transition(.opacity)
      case .loading:
        ProgressView().controlSize(.large)
      }
    }
    .animation(.easeInOut, value: auth.state.phase)
  }
}

extension View {
  func authBoundary() -> some View {
    modifier(AuthBoundaryModifier())
  }
}
