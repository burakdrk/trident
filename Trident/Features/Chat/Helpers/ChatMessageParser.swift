import DataModels
import Foundation
import TwitchIRC

struct ChatMessageParser {
  let thirdPartyEmotes: [String: DataModels.Emote]

  func parse(pm: PrivateMessage, historical: Bool = false) -> ChatMessage {
    let normalized = (pm.color.isEmpty || pm.color == "#000000") ? "#808080" : pm.color

    return ChatMessage(
      id: pm.id,
      inlines: tokenize(
        body: pm.message,
        twitchEmotes: pm.parseEmotesToDict()
      ),
      author: .init(displayName: pm.displayName, colorHex: normalized, badges: pm.badges),
      timestamp: Date(timestamp: Int(pm.tmiSentTs)),
      rawText: pm.message,
      historical: historical
    )
  }

  private func tokenize(
    body: String,
    twitchEmotes: [String: DataModels.Emote]
  ) -> [ChatMessage.Inline] {
    let chunks = body.split { $0.isWhitespace }
    var inlines: [ChatMessage.Inline] = []

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

    inlines = inlines.flatMap { [$0, ChatMessage.Inline.text(" ")] }
    inlines.removeLast() // Remove the last space

    return inlines
  }
}

private extension TwitchIRC.PrivateMessage {
  func parseEmotesToDict() -> [String: DataModels.Emote] {
    var uniqueTwitchEmotes: [String: DataModels.Emote] = [:]

    for item in parseEmotes().unique(by: \.id) {
      uniqueTwitchEmotes[item.name] = Emote(
        name: item.name,
        sourceID: item.id,
        category: .unknown,
        source: .twitch,
        overlay: false
      )
    }

    return uniqueTwitchEmotes
  }
}
