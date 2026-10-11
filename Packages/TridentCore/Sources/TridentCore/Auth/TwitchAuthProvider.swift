import DataModels
import Dependencies
import Foundation
import Utilities

actor TwitchAuthProvider: AuthProviding {
  let events: AsyncStream<AuthEvent>

  private let continuation: AsyncStream<AuthEvent>.Continuation
  private var lastEvent: AuthEvent?
  private var storedToken: AuthToken?

  var isLoggedIn: Bool {
    storedToken.map { !$0.isExpired } ?? false
  }

  @Dependency(\.secureStorage) private var secureStorage
  @Dependency(\.tokenValidator) private var tokenValidator

  init() {
    (events, continuation) = AsyncStream.makeStream(of: AuthEvent.self)
  }

  deinit {
    continuation.finish()
  }

  func deleteToken() async {
    try? await secureStorage.clear()
    setToken(nil)
  }

  /// Load the token from the secure storage and validate
  func loadSession() async {
    TridentLog.main.info("Loading Twitch session\("")")

    guard let keychainToken = await secureStorage.load(.helixAcessToken), !keychainToken.isExpired
    else {
      setToken(nil)
      return
    }

    do {
      _ = try await validateSession(token: keychainToken.value)
    } catch AuthError.invalidToken {
      // Twitch rejected it, `validateSession` already logged out.
    } catch {
      // We couldn't ask (offline, Twitch down). Trust the stored token until we can.
      TridentLog.main.warning("Could not validate Twitch session: \(error.localizedDescription)")
      setToken(keychainToken)
    }
  }

  /// Validates session and saves token to the secure storage and memory.
  ///
  /// Only a rejection from Twitch ends the session. If the check itself fails the error is thrown
  /// and the current session is left alone.
  func validateSession(token: String? = nil) async throws -> AuthToken {
    TridentLog.main.info("Validating Twitch session\("")")

    guard let tokenVal = (token ?? storedToken?.value) else {
      setToken(nil)
      throw AuthError.noToken
    }

    let validation: TokenValidation

    do {
      validation = try await tokenValidator.validate(tokenVal)
    } catch AuthError.invalidToken {
      try? await secureStorage.clear()
      setToken(nil)
      throw AuthError.invalidToken
    }

    let authToken = AuthToken(
      value: tokenVal,
      expiresAt: Date.now.addingTimeInterval(TimeInterval(validation.expiresIn))
    )

    try? await secureStorage.save(authToken, .helixAcessToken)

    setToken(authToken)
    return authToken
  }

  /// The single place the token changes, so events are emitted in the order state changes.
  private func setToken(_ token: AuthToken?) {
    storedToken = token

    let event: AuthEvent = isLoggedIn ? .loggedIn : .loggedOut
    guard event != lastEvent else { return }

    lastEvent = event
    continuation.yield(event)
  }
}

enum AuthError: LocalizedError {
  case invalidToken
  case expiredToken
  case noToken

  var errorDescription: String? {
    switch self {
    case .expiredToken:
      "Expired token"
    case .invalidToken:
      "Invalid token"
    case .noToken:
      "No token"
    }
  }
}
