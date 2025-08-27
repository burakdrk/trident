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
