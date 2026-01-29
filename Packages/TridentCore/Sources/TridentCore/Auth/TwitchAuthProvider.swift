import Alamofire
import AsyncAlgorithms
import DataModels
import Foundation
import Utilities

typealias TwitchAuthProviderDependencies = TokenStorageManagingDependency

actor TwitchAuthProvider<Dependencies: TwitchAuthProviderDependencies>: AuthProviding {
  let eventChannel = AsyncChannel<AuthEvent>()

  private var storedToken: AuthToken? {
    didSet {
      Task {
        if let storedToken, !storedToken.isExpired {
          await eventChannel.send(.loggedIn)
        } else {
          await eventChannel.send(.loggedOut)
        }
      }
    }
  }

  /// For representation of the in-memory loaded token
  var token: AuthToken? {
    if let storedToken, storedToken.isExpired {
      self.storedToken = nil
    }

    return storedToken
  }

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  deinit {
    eventChannel.finish()
  }

  func deleteToken() async {
    try? await dependencies.tokenStorage.clear()
    storedToken = nil
  }

  /// Load the token from the secure storage and validate
  func loadSession() async {
    TridentLog.main.info("Loading Twitch session\("")")

    guard let keychainToken = await dependencies.tokenStorage.load(.helixAcessToken),
          !keychainToken.isExpired
    else {
      storedToken = nil
      return
    }

    _ = try? await validateSession(token: keychainToken.value)
  }

  /// Validates session and saves token to the secure storage and memory
  func validateSession(token: String? = nil) async throws -> AuthToken {
    TridentLog.main.info("Validating Twitch session\("")")

    guard let tokenVal = (token ?? storedToken?.value) else {
      storedToken = nil
      throw AuthError.noToken
    }

    let headers: HTTPHeaders = ["Authorization": "OAuth \(tokenVal)"]
    let req = await AF
      .request("https://id.twitch.tv/oauth2/validate", headers: headers)
      .serializingDecodable(RefreshResponse.self)
      .response

    let statusCode = req.response?.statusCode ?? 401

    switch statusCode {
    case 200..<300:
      break
    default:
      storedToken = nil
      throw AuthError.invalidToken
    }

    guard let expiresIn = req.value?.expiresIn else {
      storedToken = nil
      throw AuthError.invalidToken
    }

    let authToken = AuthToken(
      value: tokenVal,
      expiresAt: Date.now.addingTimeInterval(TimeInterval(expiresIn))
    )

    try? await dependencies.tokenStorage.save(authToken, to: .helixAcessToken)

    storedToken = authToken
    return authToken
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

// MARK: - Twitch Response

private struct RefreshResponse: Codable {
  let clientID, login: String
  let scopes: [String]
  let userID: String
  let expiresIn: Int

  enum CodingKeys: String, CodingKey {
    case clientID = "client_id"
    case login, scopes
    case userID = "user_id"
    case expiresIn = "expires_in"
  }
}
