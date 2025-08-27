import Foundation

enum AuthError: LocalizedError {
  case invalidToken
  case expiredToken
  case noToken

  var errorDescription: String? {
    switch self {
    case .expiredToken:
      "Expired token"
    case .invalidToken:
      "Invalid token"
    case .noToken:
      "No token"
    }
  }
}
