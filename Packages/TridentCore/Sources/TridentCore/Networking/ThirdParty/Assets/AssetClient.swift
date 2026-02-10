import DataModels
import Dependencies

public struct AssetClient: Sendable {
  public var emotes: @Sendable (_ channelID: Channel.ID?) async -> [Emote.ID: Emote]
}

extension AssetClient: DependencyKey {
  public static var liveValue: Self {
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

public extension DependencyValues {
  var assetClient: AssetClient {
    get { self[AssetClient.self] }
    set { self[AssetClient.self] = newValue }
  }
}
