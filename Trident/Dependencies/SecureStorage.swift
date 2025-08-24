//
//  SecureStorage.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-18.
//

import Dependencies
import DependenciesMacros
import Foundation
import SimpleKeychain

@DependencyClient
struct SecureStorage {
  var load: @Sendable (_ key: SecureStorage.Keys) async -> AuthToken?
  var save: @Sendable (_ token: AuthToken, _ key: SecureStorage.Keys) async throws -> Void
  var clear: @Sendable () async throws -> Void

  enum Keys: String, Sendable, Hashable {
    #if PLUS
      case gqlAccessToken
    #endif
    case helixAcessToken
  }
}

extension SecureStorage: DependencyKey {
  static var liveValue: Self {
    let storage = KeychainSecureStorage()

    return Self { key in
      storage.load(key: key)
    } save: { token, key in
      try storage.save(token: token, key: key)
    } clear: {
      try storage.clear()
    }
  }

  static var previewValue: Self {
    actor Storage {
      var s: [SecureStorage.Keys: AuthToken] = [:]
      func set(_ token: AuthToken, forKey key: SecureStorage.Keys) {
        s[key] = token
      }

      func clear() {
        s.removeAll()
      }
    }

    let storage = Storage()

    return Self { key in
      await storage.s[key]
    } save: { token, key in
      await storage.set(token, forKey: key)
    } clear: {
      await storage.clear()
    }
  }
}

extension DependencyValues {
  var secureStorage: SecureStorage {
    get { self[SecureStorage.self] }
    set { self[SecureStorage.self] = newValue }
  }
}

// MARK: - Keychain

struct KeychainSecureStorage {
  private let keychain = SimpleKeychain()

  func load(key: SecureStorage.Keys) -> AuthToken? {
    guard
      let storedToken = try? keychain.data(
        forKey: key.rawValue
      )
    else {
      return nil
    }

    return try? JSONDecoder().decode(AuthToken.self, from: storedToken)
  }

  func save(token: AuthToken, key: SecureStorage.Keys) throws {
    let data = try JSONEncoder().encode(token)
    try keychain.set(data, forKey: key.rawValue)
  }

  func clear() throws {
    try keychain.deleteAll()
  }
}
