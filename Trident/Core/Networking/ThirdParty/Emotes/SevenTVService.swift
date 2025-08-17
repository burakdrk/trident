//
//  SevenTVService.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

import Alamofire
import Foundation

/// A service that fetches emotes from the SevenTV (7TV) API.
struct SevenTVService: ThirdPartyEmoteService {
  private let baseAPIURL = "https://7tv.io/v3"
  private let requestTimeout: TimeInterval = 5.0

  func channelEmotes(for channelID: String) async throws -> [Emote] {
    let urlString = "\(baseAPIURL)/users/twitch/\(channelID)"
    let response = try await AF
      .request(urlString, requestModifier: { $0.timeoutInterval = requestTimeout })
      .serializingDecodable(SevenTVChannelEmoteResponse.self)
      .value

    return response.emoteSet.emotes.compactMap {
      Emote(
        name: $0.name,
        id: $0.id,
        category: .channel,
        source: .seventv,
        overlay: $0.data.flags == (1 << 8),
        width: $0.data.host.files.first?.width ?? 28,
        height: $0.data.host.files.first?.height ?? 28
      )
    }
  }

  func globalEmotes() async throws -> [Emote] {
    let urlString = "\(baseAPIURL)/emote-sets/global"
    let response = try await AF
      .request(urlString, requestModifier: { $0.timeoutInterval = requestTimeout })
      .serializingDecodable(SevenTVEmoteResponse.self)
      .value

    return response.emotes.compactMap {
      Emote(
        name: $0.name,
        id: $0.id,
        category: .global,
        source: .seventv,
        overlay: $0.data.flags == (1 << 8),
        width: $0.data.host.files.first?.width ?? 28,
        height: $0.data.host.files.first?.height ?? 28
      )
    }
  }
}

// MARK: - 7TV-Specific Models

private struct SevenTVChannelEmoteResponse: Codable {
  let emoteSet: SevenTVEmoteResponse

  enum CodingKeys: String, CodingKey {
    case emoteSet = "emote_set"
  }
}

private struct SevenTVEmoteResponse: Codable {
  let emotes: [SevenTVEmote]
}

private struct SevenTVEmote: Codable {
  let id: String
  let name: String
  let data: SevenTVData
}

private struct SevenTVData: Codable {
  let host: SevenTVHost
  let flags: Int
}

private struct SevenTVHost: Codable {
  let files: [SevenTVFile]
}

private struct SevenTVFile: Codable {
  let width: Int
  let height: Int
}
