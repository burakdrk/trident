import Dependencies
import SwiftUI

private enum Constants {
  static let sleepInterval: Duration = .seconds(3_600)
}

struct AuthState: Equatable {
  enum Phase { case loading, loggedOut, loggedIn }

  var phase = Phase.loading
  var isBusy = false
  var errorMessage: String?
  var isAuthenticated: Bool {
    phase == .loggedIn
  }
}

struct AuthDependencies {
  @Dependency(\.authProvider.twitch) var authProvider
  @Dependency(\.continuousClock) var clock
  let authenticator = Authenticator()
}

typealias AuthStore = Store<AuthState, AuthDependencies>

extension AuthStore {
  static let shared = AuthStore(initialState: .init(), dependencies: .init())

  func logIn() async {
    update {
      $0.isBusy = true
      $0.errorMessage = nil
    }
    dependencies.authenticator.cancelLogIn()
    defer { update { $0.isBusy = false } }

    do {
      try await dependencies.authenticator.logIn()
    } catch OAuthError.canceled {
      update { $0.errorMessage = "Log in canceled." }
    } catch {
      update { $0.errorMessage = "Log in failed. Try again." }
    }
  }

  func logOut() async {
    await dependencies.authProvider.deleteToken()
  }

  func startHourlyValidation() async {
    while !Task.isCancelled {
      try? await dependencies.clock.sleep(for: Constants.sleepInterval)
      _ = try? await dependencies.authProvider.validateSession(token: nil)
    }
  }

  func loadSession() async {
    await dependencies.authProvider.loadSession()
  }

  func startEventListener() async {
    for await e in dependencies.authProvider.eventChannel {
      switch e {
      case .loggedIn:
        update { $0.phase = .loggedIn }
      case .loggedOut:
        update { $0.phase = .loggedOut }
      }
    }
  }
}

private struct AuthKey: EnvironmentKey {
  static var defaultValue = AuthStore.shared
}

extension EnvironmentValues {
  var auth: AuthStore {
    get { self[AuthKey.self] }
    set { self[AuthKey.self] = newValue }
  }
}
