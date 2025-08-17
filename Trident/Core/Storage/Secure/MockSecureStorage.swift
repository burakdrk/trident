//
//  MockSecureStorage.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-12.
//

final class MockSecureStorage: SecureStorage {
  private var storage: [SecureStorageKeys: AuthToken] = [:]

  func load(key: SecureStorageKeys) -> AuthToken? {
    storage[key]
  }

  func save(token: AuthToken, key: SecureStorageKeys) throws {
    storage[key] = token
  }
}
