import Foundation

enum OAuthError: Error {
  case couldNotStart
  case canceled
  case missingToken
  case system(Error)
}
