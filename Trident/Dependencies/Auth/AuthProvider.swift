//
//  AuthProvider.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-19.
//

import Dependencies
import DependenciesMacros

@DependencyClient
struct AuthProvider {
  var twitch: TwitchAuthProvider
}

extension AuthProvider: DependencyKey {
  static var liveValue: AuthProvider {
    Self(twitch: TwitchAuthProvider())
  }
}

extension DependencyValues {
  var authProvider: AuthProvider {
    get { self[AuthProvider.self] }
    set { self[AuthProvider.self] = newValue }
  }
}
