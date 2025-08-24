//
//  AssetClient.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-14.
//

import Dependencies
import DependenciesMacros

@DependencyClient
struct AssetClient {
  var emotes: @Sendable (_ channelID: String) async -> [String: Emote] = { _ in [:] }
}

extension AssetClient: DependencyKey {
  static var liveValue: Self {
    let client = ThirdPartyAssetClient(services: [
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
  var assetClient: AssetClient {
    get { self[AssetClient.self] }
    set { self[AssetClient.self] = newValue }
  }
}
