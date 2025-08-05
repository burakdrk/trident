//
//  TokenProvider.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-29.
//

import Foundation

protocol TokenProvider: Sendable {
    // Return token, if it's not expired
    // Otherwise keychain or fetch
    func getToken() async throws -> AuthToken

    // Force fetch and save to keychain
    func fetchToken() async throws -> AuthToken

    func validateToken() async -> Bool
}
