import AsyncAlgorithms
import DataModels

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

public protocol AuthProvidingDependency {
  var authProvider: any AuthProviding { get }
}
