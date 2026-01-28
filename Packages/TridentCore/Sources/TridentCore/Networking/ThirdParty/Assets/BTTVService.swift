import Alamofire
import DataModels
import Foundation

/// A service that fetches emotes from the BetterTTV (BTTV) API.
struct BTTVService: ThirdPartyAssetService {
  private let baseAPIURL = "https://api.betterttv.net/3"
  private let baseCDNURL = "https://cdn.betterttv.net/emote"
  private let requestTimeout: TimeInterval = 5.0

  func channelEmotes(for channelID: String) async throws -> [Emote] {
    let urlString = "\(baseAPIURL)/cached/users/twitch/\(channelID)"

    let response = try await AF
      .request(urlString, requestModifier: { $0.timeoutInterval = requestTimeout })
      .serializingDecodable(BTTVChannelEmoteResponse.self)
      .value

    // Use a dictionary to merge emotes. This ensures channel emotes overwrite
    // shared emotes if they have the same name, matching the original logic.
    var uniqueEmotes: [String: BTTVEmote] = [:]
    response.sharedEmotes.forEach { uniqueEmotes[$0.code] = $0 }
    response.channelEmotes.forEach { uniqueEmotes[$0.code] = $0 }

    return uniqueEmotes.values.compactMap { mapToEmote($0, .channel) }
  }

  func globalEmotes() async throws -> [Emote] {
    let urlString = "\(baseAPIURL)/cached/emotes/global"
    let bttvEmotes = try await AF
      .request(urlString, requestModifier: { $0.timeoutInterval = requestTimeout })
      .serializingDecodable([BTTVEmote].self)
      .value

    return bttvEmotes.compactMap { mapToEmote($0, .global) }
  }

  // MARK: - Private Helpers

  private func mapToEmote(_ bttvEmote: BTTVEmote, _ type: Emote.Category) -> Emote? {
    Emote(
      name: bttvEmote.code,
      sourceID: bttvEmote.id,
      category: type,
      source: .bttv,
      overlay: false,
      width: bttvEmote.width ?? 28,
      height: bttvEmote.height ?? 28
    )
  }
}

// MARK: - BTTV-Specific Models

private struct BTTVEmote: Decodable {
  let id: String
  let code: String // This is the emote's unique name
  let width: Int?
  let height: Int?
}

private struct BTTVChannelEmoteResponse: Decodable {
  let channelEmotes: [BTTVEmote]
  let sharedEmotes: [BTTVEmote]
}
