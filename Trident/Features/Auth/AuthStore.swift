//
//  AuthStore.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-19.
//

import AuthenticationServices
import Dependencies
import Foundation
import SwiftUI

@Observable
final class AuthStore: NSObject, DataStore {
  struct State: Equatable {
    var scopes = ["chat:read", "chat:edit", "user:read:follows"]

    var phase = Phase.loading
    var isBusy = false
    var errorMessage: String?
  }

  enum Action: Equatable {
    case login
    case logout
    case cancelLogIn
    case startHourlyValidation
    case stopHourlyValidation
    case loadSession

    case _setPhase(Phase)
  }

  enum Phase: Equatable { case loading, loggedOut, loggedIn }

  private(set) var state = State()
  @ObservationIgnored
  private var validatorTask: Task<Void, Never>?

  override nonisolated init() {
    super.init()
    Task { await startListening() }
  }

  deinit {
    validatorTask?.cancel()
  }

  @ObservationIgnored
  private var session: ASWebAuthenticationSession?
  @ObservationIgnored
  @Dependency(\.authProvider.twitch) private var authProvider
  @ObservationIgnored
  @Dependency(\.uuid) private var uuid
  @ObservationIgnored
  @Dependency(\.continuousClock) private var clock

  func dispatch(_ action: Action) {
    switch action {
    case .login:
      Task { @MainActor in
        state.isBusy = true
        defer { state.isBusy = false }

        do {
          _ = try await logIn()
        } catch OAuthError.canceled {
          state.errorMessage = "Log in canceled."
        } catch {
          state.errorMessage = "Log in failed. Try again."
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
    }
  }
}

// MARK: - Authentication Logic

extension AuthStore: ASWebAuthenticationPresentationContextProviding {
  private func logIn() async throws -> AuthToken {
    guard var comps = URLComponents(string: "https://id.twitch.tv/oauth2/authorize") else {
      throw OAuthError.couldNotStart
    }

    let identifier = uuid.callAsFunction().uuidString

    comps.queryItems = [
      .init(name: "client_id", value: "9bjmgzgap1vqh4ou8611ndjrg5vae6"),
      .init(name: "redirect_uri", value: "https://tridentapp.dev/oauth"),
      .init(name: "response_type", value: "token"),
      .init(name: "scope", value: state.scopes.joined(separator: " ")),
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

        guard let token = token, stateRes == identifier else {
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
      self.session = s
      if !s.start() { cont.resume(throwing: OAuthError.couldNotStart) }
    }
  }

  private func cancelLogIn() {
    session?.cancel()
    session = nil
  }

  func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }
}

// MARK: - Validation Logic

extension AuthStore {
  /// Start hourly validation. Note: it doesn't immediately validate.
  private func startHourlyValidation(interval: Duration = .seconds(3600)) {
    guard validatorTask?.isCancelled ?? true else {
      return
    }

    validatorTask = Task { [weak self] in
      guard let self else { return }

      while !Task.isCancelled {
        try? await clock.sleep(for: interval)
        _ = try? await self.authProvider.validateSession()
      }
    }
  }

  private func stopHourlyValidation() {
    validatorTask?.cancel()
    validatorTask = nil
  }
}

// MARK: - Event Listener

extension AuthStore {
  private func startListening() async {
    for await e in authProvider.events {
      switch e {
      case .loggedIn:
        dispatch(._setPhase(.loggedIn))
      case .loggedOut:
        dispatch(._setPhase(.loggedOut))
      }
    }
  }
}

// MARK: - Environment

extension AuthStore {
  nonisolated static let live = AuthStore()
}

extension EnvironmentValues {
  @Entry var auth = AuthStore.live
}
