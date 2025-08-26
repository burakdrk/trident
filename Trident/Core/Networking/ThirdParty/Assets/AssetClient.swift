//
//  AssetClient.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-14.
//

import FactoryKit

struct AssetClient: Sendable {
  var emotes: @Sendable (_ channelID: String) async -> [String: Emote]
}

private extension AssetClient {
  static var live: Self {
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

extension Container {
  var assetClient: Factory<AssetClient> {
    self { AssetClient.live }
      .cached
  }
}
