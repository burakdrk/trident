//
//  GQLTokenManager.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-28.
//

import Foundation
import SwiftUI

final class GQLTokenManager: TokenManager {
    private var window: UIWindow?
    private var token: AuthToken?
    private let fetchTimeout: TimeInterval
    private let storage: TokenStorageService

    init(fetchTimeout: TimeInterval = 30.0, storage: TokenStorageService) {
        self.fetchTimeout = fetchTimeout
        self.storage = storage
        self.token = storage.load(
            key: .GQL_ACCESS_TOKEN
        )
    }

    func getToken() async throws -> AuthToken {
        if let token, !token.isExpired {
            return token
        }

        return try await fetchToken()
    }

    func fetchToken() async throws -> AuthToken {
        try await Task.performWithTimeout(of: .seconds(fetchTimeout)) {
            @MainActor in
            try await withCheckedThrowingContinuation { continuation in
                let view = TwitchIntegrityWebView { [weak self] result in
                    self?.destroyWebView()

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
                .frame(width: 0, height: 0)

                let hostingVC = UIHostingController(rootView: view)
                let window = UIWindow(
                    frame: .init(x: 0, y: 0, width: 1, height: 1)
                )
                window.rootViewController = hostingVC
                window.windowLevel = .alert + 1
                window.isHidden = false
                window.makeKeyAndVisible()

                self.window = window
            }
        }
    }

    func validateToken() async -> Bool {
        return true  // NOT IMPLEMENTED YET
    }

    // MARK: - Private Helpers
    private func destroyWebView() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
    }
}
