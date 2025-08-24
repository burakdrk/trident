//
//  Auth.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-28.
//

import Dependencies
import Foundation

// MARK: - AuthToken

struct AuthToken: Sendable, Codable {
  let value: String
  let expiresAt: Date

  var isExpired: Bool {
    @Dependency(\.date) var date

    return date.now >= expiresAt
  }
}
