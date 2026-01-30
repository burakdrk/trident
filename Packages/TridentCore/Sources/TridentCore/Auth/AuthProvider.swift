import AsyncAlgorithms
import DataModels
import Dependencies

public enum AuthEvent: Sendable {
  case loggedOut
  case loggedIn
}

public protocol AuthProviding: Sendable {
  var eventChannel: AsyncChannel<AuthEvent> { get }

  func loadSession() async
  func validateSession(token: String?) async throws -> AuthToken
  func deleteToken() async
}

public struct AuthProvider: Sendable {
  public let twitch: any AuthProviding
}

extension AuthProvider: DependencyKey {
  public static let liveValue = AuthProvider(twitch: TwitchAuthProvider())
}

public extension DependencyValues {
  var authProvider: AuthProvider {
    get { self[AuthProvider.self] }
    set { self[AuthProvider.self] = newValue }
  }
}
