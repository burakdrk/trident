//
//  HelixTokenProvider.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

import Foundation

actor HelixTokenProvider: TokenProvider {
    private let storage: TokenStore

    init(storage: TokenStore) {
        self.storage = storage
    }

    func getToken() async throws -> AuthToken {
        AuthToken(value: "Test", expiresAt: Date.now)
    }

    func fetchToken() async throws -> AuthToken {
        AuthToken(value: "Test", expiresAt: Date.now)
    }

    func validateToken() async -> Bool {
        true
    }
}
