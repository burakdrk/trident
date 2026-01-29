import DataModels
import Foundation
import SimpleKeychain

enum TokenStorageKeys: String {
  case helixAcessToken
}

protocol TokenStorageManaging: Sendable {
  func load(_ key: TokenStorageKeys) async -> AuthToken?
  func save(_ token: AuthToken, to key: TokenStorageKeys) async throws
  func clear() async throws
}

protocol TokenStorageManagingDependency {
  var tokenStorage: any TokenStorageManaging { get }
}

struct TokenStorage: TokenStorageManaging {
  let keychain = SimpleKeychain(accessibility: .afterFirstUnlockThisDeviceOnly)

  func load(_ key: TokenStorageKeys) async -> AuthToken? {
    guard let storedToken = try? keychain.data(forKey: key.rawValue) else {
      return nil
    }

    return try? JSONDecoder.shared.decode(AuthToken.self, from: storedToken)
  }

  func save(_ token: AuthToken, to key: TokenStorageKeys) async throws {
    let data = try JSONEncoder.shared.encode(token)
    try keychain.set(data, forKey: key.rawValue)
  }

  func clear() async throws {
    try keychain.deleteAll()
  }
}
