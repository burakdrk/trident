import Alamofire
import Dependencies
import Foundation

struct TokenValidation: Codable, Sendable, Equatable {
  let clientID, login: String
  let scopes: [String]
  let userID: String
  let expiresIn: Int

  enum CodingKeys: String, CodingKey {
    case clientID = "client_id"
    case login, scopes
    case userID = "user_id"
    case expiresIn = "expires_in"
  }
}

/// Asks Twitch whether an access token is still good.
struct TokenValidator: Sendable {
  /// Throws `AuthError.invalidToken` when Twitch rejects the token. Any other error means the
  /// check itself failed (no network, server trouble) and says nothing about the token.
  var validate: @Sendable (_ token: String) async throws -> TokenValidation
}

extension TokenValidator: DependencyKey {
  static var liveValue: Self {
    Self { token in
      let headers: HTTPHeaders = ["Authorization": "OAuth \(token)"]
      let req = await AF
        .request("https://id.twitch.tv/oauth2/validate", headers: headers)
        .serializingDecodable(TokenValidation.self)
        .response

      guard let statusCode = req.response?.statusCode else {
        throw req.error ?? URLError(.notConnectedToInternet)
      }

      switch statusCode {
      case 200..<300:
        guard let value = req.value else { throw URLError(.cannotParseResponse) }
        return value
      case 401:
        throw AuthError.invalidToken
      default:
        throw URLError(.badServerResponse)
      }
    }
  }
}

extension DependencyValues {
  var tokenValidator: TokenValidator {
    get { self[TokenValidator.self] }
    set { self[TokenValidator.self] = newValue }
  }
}
