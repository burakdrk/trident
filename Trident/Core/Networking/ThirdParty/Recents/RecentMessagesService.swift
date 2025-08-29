import Alamofire
import Foundation
import TwitchIRC

struct RecentMessagesService: Sendable {
  private let baseAPIURL = "https://recent-messages.robotty.de/api/v2/recent-messages"
  private let params = ["hide_moderation_messages": "true", "hide_moderated_messages": "true"]

  func fetch(for channel: String) async -> ([ChatMessage], Set<String>) {
    let urlString = "\(baseAPIURL)/\(channel)"

    let res = try? await AF
      .request(urlString, parameters: params)
      .serializingDecodable(RecentMessagesResponse.self)
      .value

    guard let res else {
      return ([], Set<String>())
    }

    var ids = Set<String>()

    let messages = res.messages.reversed()
      .flatMap { IncomingMessage.parse(ircOutput: $0).compactMap(\.message) }
      .compactMap { message in
        if case .privateMessage(let pm) = message {
          ids.insert(pm.id)
          return ChatMessage(pm: pm, thirdPartyEmotes: [:], historical: true)
        }

        return nil
      }

    return (messages, ids)
  }

  private struct RecentMessagesResponse: Codable {
    let messages: [String]
    let error: String?
    let error_code: String?
  }
}
