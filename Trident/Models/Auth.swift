//
//  Auth.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-28.
//

import Foundation

// MARK: - AuthToken

struct AuthToken: Sendable, Codable {
  let value: String
  let expiresAt: Date

  var isExpired: Bool {
    return Date.now >= expiresAt
  }
}
