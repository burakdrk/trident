//
//  Badge.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-18.
//

import Foundation

struct Badge: Identifiable, Hashable, Sendable {
  enum Category: String, Sendable {
    case global = "Global"
    case channel = "Channel"
    case unknown
  }

  enum Source: String, Sendable {
    case twitch = "https://static-cdn.jtvnw.net/emoticons/v2/"
    case bttv = "https://cdn.betterttv.net/badges/"
    case ffz = "https://cdn.frankerfacez.com/badge/"
    case seventv = "https://cdn.7tv.app/badges/"
  }

  let name: String
  let id: String
  let category: Category
  let source: Source
  let overlay: Bool
  var width = 28
  var height = 28

  var url: URL {
    switch source {
    case .bttv:
      guard let url = URL(string: "\(source.rawValue)\(id)") else {
        fatalError("Invalid BTTV URL")
      }
      return url
    case .ffz:
      guard let url = URL(string: "\(source.rawValue)\(id)/1") else {
        fatalError("Invalid FFZ URL")
      }
      return url
    case .seventv:
      guard let url = URL(string: "\(source.rawValue)\(id)/2x.webp") else {
        fatalError("Invalid 7TV URL")
      }
      return url
    case .twitch:
      guard let url = URL(string: "\(source.rawValue)\(id)/default/dark/2.0") else {
        fatalError("Invalid Twitch URL")
      }
      return url
    }
  }

  func size(
    multiplier: CGFloat = 1.0
  ) -> CGSize {
    let multiplier = multiplier * 1.25 // Baseline multiplier for better visibility
    return CGSize(width: CGFloat(width) * multiplier, height: CGFloat(height) * multiplier)
  }

  static func == (lhs: Badge, rhs: Badge) -> Bool {
    lhs.id == rhs.id && lhs.source == rhs.source
  }
}

// MARK: - Mock Data

#if DEBUG
  extension Badge {
    static let mockOverlay = Badge(
      name: "RainTime",
      id: "01FCY771D800007PQ2DF3GDTN6",
      category: .global,
      source: .seventv,
      overlay: true,
      width: 32,
      height: 32
    )

    static let mock7tv = Badge(
      name: "sadEing",
      id: "01J3Q6RTN80004SVBK6PNC1AA8",
      category: .channel,
      source: .seventv,
      overlay: false,
      width: 32,
      height: 32
    )

    static let mocks: [Badge] = [.mockOverlay, .mock7tv]
  }
#endif
