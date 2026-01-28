import AsyncAlgorithms
import DataModels
import Dependencies

enum AuthEvent {
  case loggedOut
  case loggedIn
}

protocol AuthProviding: Sendable {
  var eventChannel: AsyncChannel<AuthEvent> { get }

  func loadSession() async
  func validateSession(token: String?) async throws -> AuthToken
  func deleteToken() async
}

struct AuthProvider {
  let twitch: any AuthProviding
}

extension AuthProvider: DependencyKey {
  static let liveValue = AuthProvider(twitch: TwitchAuthProvider())
}

extension DependencyValues {
  var authProvider: AuthProvider {
    get { self[AuthProvider.self] }
    set { self[AuthProvider.self] = newValue }
  }
}
