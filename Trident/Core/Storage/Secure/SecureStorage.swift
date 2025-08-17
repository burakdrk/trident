//
//  SecureStorage.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-30.
//

import Foundation
import SimpleKeychain

protocol SecureStorage {
  func load(key: SecureStorageKeys) -> AuthToken?
  func save(token: AuthToken, key: SecureStorageKeys) throws
}

struct KeychainSecureStorage: SecureStorage {
  private let keychain: SimpleKeychain

  init() {
    keychain = SimpleKeychain()
  }

  func load(key: SecureStorageKeys) -> AuthToken? {
    guard
      let storedToken = try? keychain.data(
        forKey: key.rawValue
      )
    else {
      return nil
    }

    return try? JSONDecoder().decode(AuthToken.self, from: storedToken)
  }

  func save(token: AuthToken, key: SecureStorageKeys) throws {
    let data = try JSONEncoder().encode(token)
    try keychain.set(data, forKey: key.rawValue)
  }
}
