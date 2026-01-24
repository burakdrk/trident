import Foundation

// MARK: - AuthToken

public struct AuthToken: Sendable, Codable {
  public let value: String
  public let expiresAt: Date

  public init(value: String, expiresAt: Date) {
    self.value = value
    self.expiresAt = expiresAt
  }

  public var isExpired: Bool {
    Date.now >= expiresAt
  }
}
