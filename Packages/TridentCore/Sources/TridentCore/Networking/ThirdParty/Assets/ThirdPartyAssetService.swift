import DataModels

protocol ThirdPartyAssetService: Sendable {
  func channelEmotes(for channelID: String) async throws -> [Emote]
  func globalEmotes() async throws -> [Emote]
}
