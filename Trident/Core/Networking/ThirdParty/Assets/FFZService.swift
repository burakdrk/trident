import Alamofire
import Foundation

/// A service that fetches emotes from the FrankerFaceZ (FFZ) API.
struct FFZService: ThirdPartyAssetService {
  private let baseAPIURL = "https://api.frankerfacez.com/v1"
  private let requestTimeout: TimeInterval = 5.0

  func channelEmotes(for channelID: String) async throws -> [Emote] {
    let urlString = "\(baseAPIURL)/room/id/\(channelID)"
    let response = try await AF
      .request(urlString, requestModifier: { $0.timeoutInterval = requestTimeout })
      .serializingDecodable(FFZChannelEmoteResponse.self)
      .value

    guard let emotes = response.sets[String(response.room.roomSet)]?.emoticons else {
      throw URLError(.badServerResponse)
    }

    return emotes.compactMap {
      Emote(
        name: $0.name,
        sourceID: String($0.id),
        category: .channel,
        source: .ffz,
        overlay: false,
        width: $0.width,
        height: $0.height
      )
    }
  }

  func globalEmotes() async throws -> [Emote] {
    let urlString = "\(baseAPIURL)/set/global"
    let response: FFZGlobalEmoteResponse = try await AF
      .request(urlString, requestModifier: { $0.timeoutInterval = requestTimeout })
      .serializingDecodable(FFZGlobalEmoteResponse.self)
      .value

    guard let emotes = response.sets[String(response.defaultSets[0])]?.emoticons else {
      throw URLError(.badServerResponse)
    }

    return emotes.compactMap {
      Emote(
        name: $0.name,
        sourceID: String($0.id),
        category: .global,
        source: .ffz,
        overlay: false,
        width: $0.width,
        height: $0.height
      )
    }
  }
}

// MARK: - FFZ-Specific Models

private struct FFZChannelEmoteResponse: Codable {
  let room: Room
  let sets: [String: Set]
}

private struct FFZGlobalEmoteResponse: Codable {
  let defaultSets: [Int]
  let sets: [String: Set]

  enum CodingKeys: String, CodingKey {
    case defaultSets = "default_sets"
    case sets
  }
}

private struct Room: Codable {
  let id, twitchID: Int
  let roomID: String
  let isGroup: Bool
  let displayName: String
  let roomSet: Int

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case twitchID = "twitch_id"
    case roomID = "id"
    case isGroup = "is_group"
    case displayName = "display_name"
    case roomSet = "set"
  }
}

private struct Set: Codable {
  let id, type: Int
  let title: String
  let emoticons: [Emoticon]

  enum CodingKeys: String, CodingKey {
    case id
    case type = "_type"
    case title, emoticons
  }
}

private struct Emoticon: Codable {
  let id: Int
  let name: String
  let height, width: Int
  let emoticonPublic, hidden, modifier: Bool
  let modifierFlags: Int
  let urls: [String: String]
  let status, usageCount: Int
  let createdAt, lastUpdated: String

  enum CodingKeys: String, CodingKey {
    case id, name, height, width
    case emoticonPublic = "public"
    case hidden, modifier
    case modifierFlags = "modifier_flags"
    case urls, status
    case usageCount = "usage_count"
    case createdAt = "created_at"
    case lastUpdated = "last_updated"
  }
}
