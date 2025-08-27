import Alamofire
import Foundation
import TwitchIRC

struct RecentMessagesService: Sendable {
  private let baseAPIURL = "https://recent-messages.robotty.de/api/v2/recent-messages"

  func fetch(for channel: String, tpEmotes: [String: Emote]) async -> ([ChatMessage], Set<String>) {
    let urlString = "\(baseAPIURL)/\(channel)"

    let res = try? await AF
      .request(urlString)
      .serializingDecodable(RecentMessagesResponse.self)
      .value

    guard let res else {
      return ([], Set<String>())
    }

    var ids = Set<String>()

    let messages = res.messages.reversed()
      .flatMap { IncomingMessage.parse(ircOutput: $0).compactMap(\.message) }
      .compactMap { message in
        if case let .privateMessage(pm) = message {
          ids.insert(pm.id)
          return ChatMessage(pm: pm, thirdPartyEmotes: tpEmotes, historical: true)
        }

        return nil
      }

    return (messages, ids)
  }
}

private struct RecentMessagesResponse: Codable {
  let messages: [String]
  let error: String?
  let error_code: String?
}
