//
//  EmoteClient.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-14.
//

import Dependencies
import DependenciesMacros

@DependencyClient
struct EmoteClient {
  var emotes: @Sendable (_ channelID: String) async -> [String: Emote] = { _ in [:] }
}

extension EmoteClient: DependencyKey {
  static var liveValue: Self {
    let client = ThirdPartyEmoteClient(services: [
      FFZService(),
      BTTVService(),
      SevenTVService()
    ])

    return Self(
      emotes: { channelID in
        await client.emotes(for: channelID)
      }
    )
  }
}

extension DependencyValues {
  var emoteClient: EmoteClient {
    get { self[EmoteClient.self] }
    set { self[EmoteClient.self] = newValue }
  }
}
