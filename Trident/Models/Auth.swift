import Foundation

// MARK: - AuthToken

struct AuthToken: Sendable, Codable {
  let value: String
  let expiresAt: Date

  var isExpired: Bool {
    Date.now >= expiresAt
  }
}
