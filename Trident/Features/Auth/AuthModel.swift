import Dependencies
import SwiftUI

private enum Constants {
  static let sleepInterval: Duration = .seconds(3_600)
}

@Observable
final class AuthModel {
  enum Phase { case loading, loggedOut, loggedIn }

  // MARK: - State

  private(set) var phase = Phase.loading
  private(set) var isBusy = false
  private(set) var errorMessage: String?
  var isAuthenticated: Bool { phase == .loggedIn }

  // MARK: - Dependencies

  @ObservationIgnored @Dependency(\.authProvider.twitch) private var authProvider
  @ObservationIgnored @Dependency(\.continuousClock) private var clock
  @ObservationIgnored private let authenticator = Authenticator()

  static let shared = AuthModel()
  private init() {}

  // MARK: - Actions

  /// Starts the OAuth flow. `isBusy` is set synchronously, so a second call while a log in is
  /// running is ignored.
  func logIn() {
    guard !isBusy else { return }
    isBusy = true
    errorMessage = nil

    Task {
      defer { isBusy = false }

      do {
        try await authenticator.logIn()
      } catch OAuthError.canceled {
        errorMessage = "Log in canceled."
      } catch {
        errorMessage = "Log in failed. Try again."
      }
    }
  }

  func logOut() async {
    await authProvider.deleteToken()
  }

  // MARK: - Lifecycle
  // Long-running work tied to the app's lifetime; called from `.task` in `TridentApp`.

  func loadSession() async {
    await authProvider.loadSession()
  }

  func startEventListener() async {
    for await event in await authProvider.eventChannel {
      switch event {
      case .loggedIn: phase = .loggedIn
      case .loggedOut: phase = .loggedOut
      }
    }
  }

  func startHourlyValidation() async {
    while !Task.isCancelled {
      try? await clock.sleep(for: Constants.sleepInterval)
      _ = try? await authProvider.validateSession(token: nil)
    }
  }
}

extension EnvironmentValues {
  @Entry var auth = AuthModel.shared
}
