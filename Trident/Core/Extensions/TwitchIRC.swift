import Foundation
import TwitchIRC

extension TwitchIRC.PrivateMessage {
  func parseEmotesToDict() -> [String: Emote] {
    var uniqueTwitchEmotes: [String: Emote] = [:]

    for item in parseEmotes().unique(by: \.id) {
      uniqueTwitchEmotes[item.name] = Emote(
        name: item.name,
        id: item.id,
        category: .unknown,
        source: .twitch,
        overlay: false
      )
    }

    return uniqueTwitchEmotes
  }
}
