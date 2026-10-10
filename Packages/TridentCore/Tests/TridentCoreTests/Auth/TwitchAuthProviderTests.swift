import DataModels
import Dependencies
import Foundation
import Testing
@testable import TridentCore

@Suite(.timeLimit(.minutes(1)))
struct TwitchAuthProviderTests {
  private static let validation = TokenValidation(
    clientID: "client",
    login: "login",
    scopes: [],
    userID: "1",
    expiresIn: 3_600
  )

  private static func storage(holding token: AuthToken?) async -> SecureStorage {
    let storage = SecureStorage.testValue
    if let token { try? await storage.save(token, .helixAcessToken) }
    return storage
  }

  private static func validToken(_ value: String = "stored") -> AuthToken {
    AuthToken(value: value, expiresAt: .now.addingTimeInterval(3_600))
  }

  private func makeProvider(
    storage: SecureStorage,
    validate: @escaping @Sendable (String) async throws -> TokenValidation
  ) -> TwitchAuthProvider {
    withDependencies {
      $0.secureStorage = storage
      $0.tokenValidator = TokenValidator(validate: validate)
    } operation: {
      TwitchAuthProvider()
    }
  }

  /// Events are buffered by the provider, so reading never has to wait for a emission that
  /// already happened.
  private func events(_ count: Int, from provider: TwitchAuthProvider) async -> [AuthEvent] {
    var iterator = await provider.events.makeAsyncIterator()
    var result: [AuthEvent] = []
    while result.count < count, let event = await iterator.next() {
      result.append(event)
    }
    return result
  }

  // MARK: - Loading

  @Test func loadSessionLogsInWhenStoredTokenIsValid() async {
    let provider = await makeProvider(storage: Self.storage(holding: Self.validToken())) { _ in
      Self.validation
    }

    await provider.loadSession()

    #expect(await events(1, from: provider) == [.loggedIn])
  }

  @Test func loadSessionLogsOutWithoutStoredToken() async {
    let provider = await makeProvider(storage: Self.storage(holding: nil)) { _ in
      Self.validation
    }

    await provider.loadSession()

    #expect(await events(1, from: provider) == [.loggedOut])
  }

  @Test func loadSessionLogsOutAndForgetsTheTokenWhenTwitchRejectsIt() async {
    let storage = await Self.storage(holding: Self.validToken())
    let provider = makeProvider(storage: storage) { _ in throw AuthError.invalidToken }

    await provider.loadSession()

    #expect(await events(1, from: provider) == [.loggedOut])
    #expect(await storage.load(.helixAcessToken) == nil)
  }

  @Test func loadSessionKeepsUserLoggedInWhenOffline() async {
    let storage = await Self.storage(holding: Self.validToken())
    let provider = makeProvider(storage: storage) { _ in throw URLError(.notConnectedToInternet) }

    await provider.loadSession()

    #expect(await events(1, from: provider) == [.loggedIn])
    #expect(await storage.load(.helixAcessToken) != nil)
  }

  @Test func loadSessionLogsOutWhenStoredTokenExpired() async {
    let expired = AuthToken(value: "old", expiresAt: .now.addingTimeInterval(-1))
    let provider = await makeProvider(storage: Self.storage(holding: expired)) { _ in
      Self.validation
    }

    await provider.loadSession()

    #expect(await events(1, from: provider) == [.loggedOut])
  }

  // MARK: - Revalidation

  @Test func failedCheckDoesNotLogOutAnActiveSession() async throws {
    let isOffline = LockIsolated(false)
    let provider = await makeProvider(storage: Self.storage(holding: nil)) { _ in
      if isOffline.value { throw URLError(.notConnectedToInternet) }
      return Self.validation
    }

    _ = try await provider.validateSession(token: "fresh")
    #expect(await provider.isLoggedIn)

    isOffline.setValue(true)
    await #expect(throws: URLError.self) {
      try await provider.validateSession(token: nil)
    }

    #expect(await provider.isLoggedIn)
  }

  @Test func rejectedTokenLogsOutAnActiveSession() async throws {
    let isRejected = LockIsolated(false)
    let provider = await makeProvider(storage: Self.storage(holding: nil)) { _ in
      if isRejected.value { throw AuthError.invalidToken }
      return Self.validation
    }

    _ = try await provider.validateSession(token: "fresh")
    isRejected.setValue(true)
    await #expect(throws: AuthError.self) {
      try await provider.validateSession(token: nil)
    }

    #expect(await !provider.isLoggedIn)
  }

  // MARK: - Events

  @Test func eventsArriveInTheOrderStateChanged() async throws {
    let isRejected = LockIsolated(false)
    let provider = await makeProvider(storage: Self.storage(holding: nil)) { _ in
      if isRejected.value { throw AuthError.invalidToken }
      return Self.validation
    }

    _ = try await provider.validateSession(token: "fresh")
    isRejected.setValue(true)
    _ = try? await provider.validateSession(token: nil)
    isRejected.setValue(false)
    _ = try await provider.validateSession(token: "fresh again")
    await provider.deleteToken()

    #expect(
      await events(4, from: provider) == [.loggedIn, .loggedOut, .loggedIn, .loggedOut]
    )
  }

  @Test func repeatedValidationEmitsOnlyOnChange() async throws {
    let provider = await makeProvider(storage: Self.storage(holding: nil)) { _ in
      Self.validation
    }

    _ = try await provider.validateSession(token: "a")
    _ = try await provider.validateSession(token: "a")
    _ = try await provider.validateSession(token: "a")
    await provider.deleteToken()

    #expect(await events(2, from: provider) == [.loggedIn, .loggedOut])
  }

  @Test func loggingInDoesNotWaitForAListener() async throws {
    let provider = await makeProvider(storage: Self.storage(holding: nil)) { _ in
      Self.validation
    }

    // Nobody is reading `events`; this must still return.
    _ = try await provider.validateSession(token: "a")
    #expect(await provider.isLoggedIn)
  }
}

extension AuthEvent: Equatable {}
