import FactoryKit
import SwiftUI

struct AuthState: StoreState {
  enum Phase { case loading, loggedOut, loggedIn }

  var phase = Phase.loading
  var isBusy = false
  var errorMessage: String?
  var isAuthenticated: Bool {
    phase == .loggedIn
  }
}

struct AuthDependencies: StoreDependencies {
  let authenticator = Authenticator()
  let authProvider = Container.shared.authProvider().twitch
}

typealias AuthStore = Store<AuthState, AuthDependencies>

extension AuthStore {
  @MainActor static let shared = AuthStore()

  func logIn() async {
    update {
      $0.isBusy = true
      $0.errorMessage = nil
    }
    deps.authenticator.cancelLogIn()
    defer { update { $0.isBusy = false } }

    do {
      try await deps.authenticator.logIn()
    } catch OAuthError.canceled {
      update { $0.errorMessage = "Log in canceled." }
    } catch {
      update { $0.errorMessage = "Log in failed. Try again." }
    }
  }

  func logOut() async {
    await deps.authProvider.deleteToken()
  }

  func startHourlyValidation(interval: Duration = .seconds(3_600)) async {
    while !Task.isCancelled {
      try? await Task.sleep(for: interval)
      _ = try? await deps.authProvider.validateSession()
    }
  }

  func loadSession() async {
    await deps.authProvider.loadSession()
  }

  func startEventListener() async {
    for await e in deps.authProvider.events {
      switch e {
      case .loggedIn:
        update { $0.phase = .loggedIn }
      case .loggedOut:
        update { $0.phase = .loggedOut }
      }
    }
  }
}

struct AuthKey: @MainActor EnvironmentKey {
  @MainActor static var defaultValue = AuthStore.shared
}

extension EnvironmentValues {
  @MainActor
  var auth: AuthStore {
    get { self[AuthKey.self] }
    set { self[AuthKey.self] = newValue }
  }
}
