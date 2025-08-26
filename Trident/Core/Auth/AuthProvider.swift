//
//  AuthProvider.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-19.
//

import FactoryKit

struct AuthProvider {
  var twitch: TwitchAuthProvider
}

private extension AuthProvider {
  static var live: Self {
    Self(twitch: TwitchAuthProvider())
  }
}

extension Container {
  var authProvider: Factory<AuthProvider> {
    self { AuthProvider.live }
      .singleton
  }
}
