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
    private let storage: TokenStore

    init(fetchTimeout: TimeInterval = 30.0, storage: TokenStore) {
        self.fetchTimeout = fetchTimeout
        self.storage = storage
        self.token = storage.load(key: .GQL_ACCESS_TOKEN)
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
                    case .success(let tokenRes):
                        let newToken = AuthToken(
                            value: tokenRes.token,
                            expiresAt: Date(
                                timeIntervalSince1970: TimeInterval(
                                    tokenRes.expiration / 1000
                                )
                            )
                        )

                        try? self?.storage.save(
                            token: newToken,
                            key: .GQL_ACCESS_TOKEN
                        )

                        continuation.resume(
                            returning: newToken
                        )
                    case .failure(let err):
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
