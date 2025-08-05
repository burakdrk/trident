//
//  TokenStore.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-30.
//

import Foundation
import SimpleKeychain

struct TokenStore {
    private let keychain: SimpleKeychain

    init(service: String = Bundle.main.bundleIdentifier!) {
        self.keychain = SimpleKeychain(service: service)
    }

    func load(key: KeychainKeys) -> AuthToken? {
        guard
            let storedToken = try? keychain.data(
                forKey: key.rawValue
            )
        else {
            return nil
        }

        return try? JSONDecoder().decode(AuthToken.self, from: storedToken)
    }

    func save(token: AuthToken, key: KeychainKeys) throws {
        let data = try JSONEncoder().encode(token)
        try keychain.set(data, forKey: key.rawValue)
    }
}
