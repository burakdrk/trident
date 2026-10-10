import Alamofire
import DataModels
import Dependencies
import Foundation
import TwitchIRC

private enum Constants {
  static let baseAPIURL = "https://recent-messages.robotty.de/api/v2/recent-messages"
  static let timeout: TimeInterval = 5
  static let params = [
    "hide_moderation_messages": "true",
    "hide_moderated_messages": "true"
  ]
}

public struct RecentMessagesService: Sendable {
  public init() {}

  /// The channel's recent chat, oldest first. Empty if the service can't be reached, since chat
  /// is perfectly usable without it.
  public func fetch(
    for channel: String,
    emotes: EmotesByName
  ) async -> [ChatMessage] {
    let urlString = "\(Constants.baseAPIURL)/\(channel)"

    let res = try? await AF
      .request(urlString, parameters: Constants.params) { $0.timeoutInterval = Constants.timeout }
      .serializingDecodable(RecentMessagesResponse.self)
      .value

    guard let res else { return [] }

    return Self.parse(lines: res.messages, emotes: emotes)
  }

  /// - Parameter lines: Raw IRC lines in the order the service returns them (oldest first).
  static func parse(lines: [String], emotes: EmotesByName) -> [ChatMessage] {
    let parser = ChatMessageParser(thirdPartyEmotes: emotes)

    return lines
      .flatMap { IncomingMessage.parse(ircOutput: $0).compactMap(\.message) }
      .compactMap { message in
        guard case let .privateMessage(pm) = message else { return nil }
        return parser.parse(pm: pm, historical: true)
      }
  }

  private struct RecentMessagesResponse: Decodable {
    let messages: [String]
  }
}

// MARK: - Dependency

public struct RecentMessagesClient: Sendable {
  /// The channel's recent chat, oldest first.
  public var fetch: @Sendable (
    _ channel: String,
    _ emotes: EmotesByName
  ) async -> [ChatMessage]

  public init(
    fetch: @escaping @Sendable (
      _ channel: String,
      _ emotes: EmotesByName
    ) async -> [ChatMessage]
  ) {
    self.fetch = fetch
  }
}

extension RecentMessagesClient: DependencyKey {
  public static let liveValue = Self { channel, emotes in
    await RecentMessagesService().fetch(for: channel, emotes: emotes)
  }
}

public extension DependencyValues {
  var recentMessages: RecentMessagesClient {
    get { self[RecentMessagesClient.self] }
    set { self[RecentMessagesClient.self] = newValue }
  }
}
