//
//  Emote.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

import Foundation

struct Emote: Identifiable, Equatable, Sendable {
  let name: String
  let id: String
  let type: EmoteType
  let source: EmoteSource
  var width: Int = 28
  var height: Int = 28

  var url: URL {
    switch source {
    case .bttv:
      return URL(string: "\(source.rawValue)\(id)/2x.webp")!
    case .ffz:
      return URL(string: "\(source.rawValue)\(id)/2")!
    case .seventv:
      return URL(string: "\(source.rawValue)\(id)/2x.webp")!
    case .twitch:
      return URL(string: "\(source.rawValue)\(id)/default/dark/2.0")!
    }
  }

  func size(
    fontHeight: CGFloat,
    multiplier: CGFloat = 1.0
  ) -> CGSize {
    let multiplier = 2.0 * multiplier

    let height = fontHeight
    let ratio = CGFloat(self.width) / CGFloat(self.height)
    let width = (height * ratio)
    return CGSize(width: width * multiplier, height: height * multiplier)
  }

  static func == (lhs: Emote, rhs: Emote) -> Bool {
    lhs.id == rhs.id && lhs.source == rhs.source
  }
}

enum EmoteType {
  case global
  case channel
  case personal // Not implemented
  case unknown
}

enum EmoteSource: String {
  case twitch = "https://static-cdn.jtvnw.net/emoticons/v2/"
  case bttv = "https://cdn.betterttv.net/emote/"
  case ffz = "https://cdn.frankerfacez.com/emote/"
  case seventv = "https://cdn.7tv.app/emote/"
}

extension Emote {
  static let mock = Emote(
    name: "MockEmote",
    id: "mock123",
    type: .global,
    source: .twitch,
    width: 28,
    height: 28
  )
}
