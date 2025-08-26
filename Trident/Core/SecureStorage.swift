//
//  SecureStorage.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-18.
//

import FactoryKit
import Foundation
import SimpleKeychain

struct SecureStorage {
  var load: @Sendable (_ key: SecureStorage.Keys) async -> AuthToken?
  var save: @Sendable (_ token: AuthToken, _ key: SecureStorage.Keys) async throws -> Void
  var clear: @Sendable () async throws -> Void

  enum Keys: String {
    #if PLUS
      case gqlAccessToken
    #endif
    case helixAcessToken
  }
}

private extension SecureStorage {
  static var live: Self {
    let keychain = SimpleKeychain(accessibility: .afterFirstUnlockThisDeviceOnly)

    return Self { key in
      guard let storedToken = try? keychain.data(forKey: key.rawValue) else {
        return nil
      }

      return try? JSONDecoder.shared.decode(AuthToken.self, from: storedToken)
    } save: { token, key in
      let data = try JSONEncoder.shared.encode(token)
      try keychain.set(data, forKey: key.rawValue)
    } clear: {
      try keychain.deleteAll()
    }
  }

  actor MemoryStorage {
    var s: [SecureStorage.Keys: AuthToken] = [:]
    func set(_ token: AuthToken, forKey key: SecureStorage.Keys) {
      s[key] = token
    }

    func clear() {
      s.removeAll()
    }
  }

  static var mock: Self {
    let storage = MemoryStorage()

    return Self { key in
      await storage.s[key]
    } save: { token, key in
      await storage.set(token, forKey: key)
    } clear: {
      await storage.clear()
    }
  }
}

extension Container {
  var secureStorage: Factory<SecureStorage> {
    self { SecureStorage.live }
      .cached
      .onTest { SecureStorage.mock }
      .onPreview { SecureStorage.mock }
  }
}
