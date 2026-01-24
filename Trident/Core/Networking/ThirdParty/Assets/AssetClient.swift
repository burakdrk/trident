import Dependencies

struct AssetClient: Sendable {
  var emotes: @Sendable (_ channelID: String?) async -> [String: Emote]
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
