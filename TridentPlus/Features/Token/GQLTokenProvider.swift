//
//  GQLTokenProvider.swift
//  TridentPlus
//
//  Created by Burak Duruk on 2025-07-28.
//

import Foundation

@MainActor
final class GQLTokenProvider: TokenProvider {
  private var token: AuthToken?
  private var fetcher: TwitchIntegrityFetcher?
  private let fetchTimeout: TimeInterval
  private let storage: SecureStorage

  init(fetchTimeout: TimeInterval = 30.0, storage: SecureStorage) {
    self.fetchTimeout = fetchTimeout
    self.storage = storage
    token = storage.load(key: .gqlAccessToken)
  }

  func getToken() async throws -> AuthToken {
    if let token, !token.isExpired {
      return token
    }

    return try await fetchToken()
  }

  func fetchToken() async throws -> AuthToken {
    try await Task.performWithTimeout(of: .seconds(fetchTimeout)) { @MainActor in
      try await withCheckedThrowingContinuation { continuation in
        self.fetcher = TwitchIntegrityFetcher { [weak self] result in
          switch result {
          case let .success(tokenRes):
            let newToken = AuthToken(
              value: tokenRes.token,
              expiresAt: Date(timestamp: tokenRes.expiration)
            )

            try? self?.storage.save(
              token: newToken,
              key: .gqlAccessToken
            )

            continuation.resume(
              returning: newToken
            )
          case let .failure(err):
            continuation.resume(throwing: err)
          }
        }

        self.fetcher?.start()
      }
    }
  }

  func validateToken() async -> Bool {
    return true // NOT IMPLEMENTED YET
  }
}
