import AuthenticationServices
import FactoryKit
import SwiftUI

@Observable
final class AuthStore: NSObject, DataStore {
  struct State: Equatable {
    var phase = Phase.loading
    var isBusy = false
    var errorMessage: String?
  }

  enum Action {
    case login
    case logout
    case cancelLogIn
    case startHourlyValidation
    case stopHourlyValidation
    case loadSession

    case _setPhase(Phase)
    case _setErrorMessage(String?)
    case _setIsBusy(Bool)
  }

  enum Phase { case loading, loggedOut, loggedIn }

  private(set) var state = State()
  private let scopes = ["chat:read", "chat:edit", "user:read:follows"]

  @ObservationIgnored private var validatorTask: Task<Void, Never>?
  @ObservationIgnored private var session: ASWebAuthenticationSession?
  @ObservationIgnored private var authProvider = Container.shared.authProvider().twitch

  override private nonisolated init() {
    super.init()

    // Non-isolated listener task
    Task { [dispatch, authProvider] in
      for await e in authProvider.events {
        switch e {
        case .loggedIn:
          await dispatch(._setPhase(.loggedIn))
        case .loggedOut:
          await dispatch(._setPhase(.loggedOut))
        }
      }
    }
  }

  deinit { validatorTask?.cancel() }

  func dispatch(_ action: Action) {
    switch action {
    case .login:
      Task {
        dispatch(._setIsBusy(true))
        dispatch(.cancelLogIn)
        defer { dispatch(._setIsBusy(false)) }

        do {
          _ = try await logIn()
        } catch OAuthError.canceled {
          dispatch(._setErrorMessage("Log in canceled."))
        } catch {
          dispatch(._setErrorMessage("Log in failed. Try again."))
        }
      }

    case .logout:
      Task { await authProvider.deleteToken() }

    case .cancelLogIn:
      cancelLogIn()

    case .startHourlyValidation:
      startHourlyValidation()

    case .stopHourlyValidation:
      stopHourlyValidation()

    case .loadSession:
      Task { await authProvider.loadSession() }

    case let ._setPhase(phase):
      state.phase = phase

    case let ._setErrorMessage(msg):
      state.errorMessage = msg

    case let ._setIsBusy(isBusy):
      state.isBusy = isBusy
    }
  }
}

// MARK: - Authentication Logic

extension AuthStore: ASWebAuthenticationPresentationContextProviding {
  private func logIn() async throws -> AuthToken {
    guard var comps = URLComponents(string: "https://id.twitch.tv/oauth2/authorize") else {
      throw OAuthError.couldNotStart
    }

    let identifier = UUID().uuidString

    comps.queryItems = [
      .init(name: "client_id", value: "9bjmgzgap1vqh4ou8611ndjrg5vae6"),
      .init(name: "redirect_uri", value: "https://tridentapp.dev/oauth"),
      .init(name: "response_type", value: "token"),
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
        callback: .https(host: "tridentapp.dev", path: "/oauth")
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

  private func cancelLogIn() {
    session?.cancel()
    session = nil
  }

  func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
    ASPresentationAnchor()
  }
}

// MARK: - Validation Logic

extension AuthStore {
  /// Start hourly validation. Note: it doesn't immediately validate.
  private func startHourlyValidation(interval: Duration = .seconds(3_600)) {
    guard validatorTask?.isCancelled ?? true else {
      return
    }

    validatorTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: interval)
        _ = try? await self?.authProvider.validateSession()
      }
    }
  }

  private func stopHourlyValidation() {
    validatorTask?.cancel()
    validatorTask = nil
  }
}

// MARK: - Environment

extension AuthStore {
  nonisolated static let shared = AuthStore()
}

extension EnvironmentValues {
  @Entry var auth = AuthStore.shared
}
