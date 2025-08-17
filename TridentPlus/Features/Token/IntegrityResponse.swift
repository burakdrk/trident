//
//  IntegrityResponse.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

import Foundation

// MARK: - IntegrityResponse

struct IntegrityResponse: Codable {
  let token: String
  let expiration: Int
  let requestID: String

  enum CodingKeys: String, CodingKey {
    case token, expiration
    case requestID = "request_id"
  }
}
