import DataModels
import Foundation
import TwitchIRC

extension TwitchIRC.PrivateMessage {
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
