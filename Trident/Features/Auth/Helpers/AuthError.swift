//
//  AuthError.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-19.
//

import Foundation

enum AuthError: LocalizedError {
  case invalidToken
  case expiredToken
  case noToken

  var errorDescription: String? {
    switch self {
    case .expiredToken:
      return "Expired token"
    case .invalidToken:
      return "Invalid token"
    case .noToken:
      return "No token"
    }
  }
}
