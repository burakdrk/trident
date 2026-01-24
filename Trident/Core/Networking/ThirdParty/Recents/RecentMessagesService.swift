import Foundation
import Models
import TwitchIRC

private enum Constants {
  static let baseAPIURL = "https://recent-messages.robotty.de/api/v2/recent-messages"
  static let params = [
    "hide_moderation_messages": "true",
    "hide_moderated_messages": "true"
  ]
}

struct RecentMessagesService: Sendable {
  func fetch(for channel: String, emotes: [String: Models.Emote]) async -> ([ChatMessage], Set<String>) {
    let urlString = "\(Constants.baseAPIURL)/\(channel)"

    let res = try? await AF
      .request(urlString, parameters: Constants.params)
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
          return ChatMessage(pm: pm, thirdPartyEmotes: emotes, historical: true)
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
