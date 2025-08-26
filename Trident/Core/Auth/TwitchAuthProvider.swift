//
//  TwitchAuthProvider.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-19.
//

import Alamofire
import FactoryKit
import Foundation

actor TwitchAuthProvider: EventEmitting {
  enum Event: Sendable, Equatable, Codable {
    case loggedOut
    case loggedIn
  }

  let eventChannel = EventChannel(Event.self)

  private var storedToken: AuthToken? {
    didSet {
      if let storedToken = storedToken, !storedToken.isExpired {
        emit(.loggedIn)
      } else {
        emit(.loggedOut)
      }
    }
  }

  /// For representation of the in-memory loaded token
  var token: AuthToken? {
    if let storedToken = storedToken, storedToken.isExpired {
      self.storedToken = nil
    }

    return storedToken
  }

  @LazyInjected(\.secureStorage) private var secureStorage

  func deleteToken() async {
    try? await secureStorage.clear()
    storedToken = nil
  }

  /// Load the token from the secure storage and validate
  func loadSession() async {
    TridentLog.main.info("Loading Twitch session\("")")

    guard let keychainToken = await secureStorage.load(.helixAcessToken),
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
    case 200 ..< 300:
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

    try? await secureStorage.save(authToken, .helixAcessToken)

    storedToken = authToken
    return authToken
  }
}

// MARK: - Twitch Response

extension TwitchAuthProvider {
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
}
