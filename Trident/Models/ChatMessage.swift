//
//  Message.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

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
    case emote(Emote)
  }

  let id: String
  let author: Author
  let timestamp: Date
  let inlines: [Inline]
  let rawText: String

  init(pm: PrivateMessage, thirdPartyEmotes: [String: Emote]) {
    let normalized = (pm.color.isEmpty || pm.color == "#000000") ? "#808080" : pm.color

    id = pm.id
    author = .init(displayName: pm.displayName, colorHex: normalized, badges: pm.badges)
    timestamp = Date(timestamp: Int(pm.tmiSentTs))
    rawText = pm.message
    inlines = ChatMessage.tokenize(
      body: pm.message,
      twitchEmotes: pm.parseEmotes(),
      thirdPartyEmotes: thirdPartyEmotes
    )
  }

  static func == (left: ChatMessage, right: ChatMessage) -> Bool { left.id == right.id }
}

// MARK: - Tokenization

extension ChatMessage {
  private static func tokenize(
    body: String,
    twitchEmotes: [TwitchIRC.Emote],
    thirdPartyEmotes: [String: Emote]
  ) -> [Inline] {
    var uniqueTwitchEmotes: [String: Emote] = [:]

    for item in twitchEmotes.unique(by: \.id) {
      uniqueTwitchEmotes[item.name] = Emote(
        name: item.name,
        id: item.id,
        category: .unknown,
        source: .twitch,
        overlay: false
      )
    }

    var inlines = body
      .split(whereSeparator: { $0.isWhitespace })
      .map(String.init)
      .map { part in
        let emote = uniqueTwitchEmotes[part] ?? thirdPartyEmotes[part]

        if let emote = emote {
          return Inline.emote(emote)
        }

        return Inline.text(part)
      }
      .flatMap { [$0, Inline.text(" ")] }

    // Remove trailing space added by flatMap
    inlines.removeLast()

    return regroupText(inlines)
  }

  private static func regroupText(_ inlines: [Inline]) -> [Inline] {
    var result: [Inline] = []

    for item in inlines {
      if case let .text(text) = item, let last = result.last, case let .text(lastText) = last {
        result[result.count - 1] = .text(lastText + text)
      } else {
        result.append(item)
      }
    }

    return result
  }
}

// MARK: - Mock Data

#if DEBUG
  extension ChatMessage {
    static let mock: ChatMessage = {
      let string = "@badge-info=;badges=global_mod/1,turbo/1;color=#0D4200;display-name=ronni;emotes=25:0-4,12-16/1902:6-10;id=b34ccfc7-4977-403a-8a94-33c6bac34fb8;mod=0;room-id=1337;subscriber=0;tmi-sent-ts=1507246572675;turbo=1;user-id=1337;user-type=global_mod :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :Kappa Keepo Kappa sadEing RainTime"

      let messages = IncomingMessage.parse(ircOutput: string)
      guard case let .privateMessage(pm) = messages.first?.message as? IncomingMessage else {
        return ChatMessage(pm: PrivateMessage(), thirdPartyEmotes: [:])
      }

      return ChatMessage(pm: pm, thirdPartyEmotes: [
        Emote.mock7tv.name: Emote.mock7tv,
        Emote.mockOverlay.name: Emote.mockOverlay
      ])
    }()
  }
#endif
