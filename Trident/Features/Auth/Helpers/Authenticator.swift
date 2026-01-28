import AuthenticationServices
import DataModels
import Dependencies

private enum Constants {
  static let oauthURL = "https://id.twitch.tv/oauth2/authorize"
  static let clientID = "9bjmgzgap1vqh4ou8611ndjrg5vae6"
  static let redirectURI = "https://tridentapp.dev/oauth"
  static let responseType = "token"
  static let hostName = "tridentapp.dev"
}

final class Authenticator: NSObject, ASWebAuthenticationPresentationContextProviding {
  private let scopes = ["chat:read", "chat:edit", "user:read:follows"]
  private var session: ASWebAuthenticationSession?
  @Dependency(\.authProvider.twitch) private var authProvider

  @discardableResult func logIn() async throws -> AuthToken {
    guard var comps = URLComponents(string: Constants.oauthURL) else {
      throw OAuthError.couldNotStart
    }

    let identifier = UUID().uuidString

    comps.queryItems = [
      .init(name: "client_id", value: Constants.clientID),
      .init(name: "redirect_uri", value: Constants.redirectURI),
      .init(name: "response_type", value: Constants.responseType),
      .init(name: "scope", value: scopes.joined(separator: " ")),
      .init(name: "state", value: identifier)
    ]

    guard let authURL = comps.url else {
      throw OAuthError.couldNotStart
    }

    return try await withCheckedThrowingContinuation { [weak self] cont in
      guard let self else { cont.resume(throwing: OAuthError.couldNotStart); return }

      let s = ASWebAuthenticationSession(
        url: authURL,
        callback: .https(host: Constants.hostName, path: "/oauth")
      ) { callbackURL, error in
        defer { self.session = nil }

        if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
          cont.resume(throwing: OAuthError.canceled); return
        }
        if let error { cont.resume(throwing: OAuthError.system(error)); return }

        let frag = URLComponents(string: "dummy://?\(callbackURL?.fragment ?? "")")

        let token = frag?.queryItems?.first(where: { $0.name == "access_token" })?.value
        let stateRes = frag?.queryItems?.first(where: { $0.name == "state" })?.value

        guard let token, stateRes == identifier else {
          cont.resume(throwing: OAuthError.missingToken)
          return
        }

        Task { @MainActor in
          do {
            let authToken = try await self.authProvider.validateSession(token: token)
            cont.resume(returning: authToken)
          } catch {
            cont.resume(throwing: OAuthError.missingToken)
          }
        }
      }

      s.prefersEphemeralWebBrowserSession = true
      s.presentationContextProvider = self
      session = s
      if !s.start() { cont.resume(throwing: OAuthError.couldNotStart) }
    }
  }

  func cancelLogIn() {
    session?.cancel()
    session = nil
  }

  func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
    ASPresentationAnchor()
  }
}
