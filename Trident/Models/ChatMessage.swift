import Foundation
import TwitchIRC

struct ChatMessage: Identifiable, Hashable, Sendable {
  struct Author: Hashable, Sendable {
    let displayName: String
    let colorHex: String
    let badges: [String]
  }

  enum Inline: Hashable, Sendable {
    case text(String)
    case emote([Emote]) // Array for overlay emotes
  }

  let id: String
  let author: Author
  let timestamp: Date
  let inlines: [Inline]
  let rawText: String
  let historical: Bool

  init(pm: PrivateMessage, thirdPartyEmotes: [String: Emote], historical: Bool = false) {
    let normalized = (pm.color.isEmpty || pm.color == "#000000") ? "#808080" : pm.color

    id = pm.id
    author = .init(displayName: pm.displayName, colorHex: normalized, badges: pm.badges)
    timestamp = Date(timestamp: Int(pm.tmiSentTs))
    rawText = pm.message
    self.historical = historical
    inlines = ChatMessage.tokenize(
      body: pm.message,
      twitchEmotes: pm.parseEmotesToDict(),
      thirdPartyEmotes: thirdPartyEmotes
    )
  }

  static func == (left: ChatMessage, right: ChatMessage) -> Bool { left.id == right.id }
}

// MARK: - Tokenization

extension ChatMessage {
  private static func tokenize(
    body: String,
    twitchEmotes: [String: Emote],
    thirdPartyEmotes: [String: Emote]
  ) -> [Inline] {
    let chunks = body.split { $0.isWhitespace }
    var inlines: [Inline] = []

    for chunk in chunks {
      let part = String(chunk)
      let emote = twitchEmotes[part] ?? thirdPartyEmotes[part]

      if let emote {
        if emote.overlay, !inlines.isEmpty, case let .emote(lastEmotes) = inlines.last {
          inlines[inlines.count - 1] = .emote(lastEmotes + [emote])
        } else {
          inlines.append(.emote([emote]))
        }
      } else {
        if !inlines.isEmpty, case let .text(lastText) = inlines.last {
          inlines[inlines.count - 1] = .text(lastText + " " + part)
        } else {
          inlines.append(.text(part))
        }
      }
    }

    inlines = inlines.flatMap { [$0, Inline.text(" ")] }
    inlines.removeLast() // Remove the last space

    return inlines
  }
}

// MARK: - Mock Data

extension ChatMessage {
  static var mock: ChatMessage {
    let string = "@badge-info=;badges=global_mod/1,turbo/1;color=#0D4200;display-name=ronni;emotes=25:0-4,12-16/1902:6-10;id=\(UUID().uuidString);mod=0;room-id=1337;subscriber=0;tmi-sent-ts=1507246572675;turbo=1;user-id=1337;user-type=global_mod :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :Kappa Keepo Kappa sadEing RainTime"

    let messages = IncomingMessage.parse(ircOutput: string)
    guard case let .privateMessage(pm) = messages.first?.message as? IncomingMessage else {
      return ChatMessage(pm: PrivateMessage(), thirdPartyEmotes: [:])
    }

    return ChatMessage(pm: pm, thirdPartyEmotes: [
      Emote.mock7tv.name: Emote.mock7tv,
      Emote.mockOverlay.name: Emote.mockOverlay
    ])
  }
}
