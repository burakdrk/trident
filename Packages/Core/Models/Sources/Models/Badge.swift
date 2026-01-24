import Foundation

public struct Badge: Identifiable, Hashable, Sendable {
  public enum Category: String, Sendable {
    case global = "Global"
    case channel = "Channel"
    case unknown
  }

  public enum Source: String, Sendable {
    case twitch = "https://static-cdn.jtvnw.net/emoticons/v2/"
    case bttv = "https://cdn.betterttv.net/badges/"
    case ffz = "https://cdn.frankerfacez.com/badge/"
    case seventv = "https://cdn.7tv.app/badges/"
  }

  public let name: String
  public let id: String
  public let category: Category
  public let source: Source
  public let overlay: Bool
  public var width = 28
  public var height = 28

  public var url: URL {
    switch source {
    case .bttv:
      URL.make("\(source.rawValue)\(id)")
    case .ffz:
      URL.make("\(source.rawValue)\(id)/1")
    case .seventv:
      URL.make("\(source.rawValue)\(id)/2x.webp")
    case .twitch:
      URL.make("\(source.rawValue)\(id)/default/dark/2.0")
    }
  }

  public func size(
    multiplier: CGFloat = 1.0
  ) -> CGSize {
    let multiplier = multiplier * 1.25 // Baseline multiplier for better visibility
    return CGSize(width: CGFloat(width) * multiplier, height: CGFloat(height) * multiplier)
  }

  public static func == (lhs: Badge, rhs: Badge) -> Bool {
    lhs.id == rhs.id && lhs.source == rhs.source
  }
}

// MARK: - Mock Data

public extension Badge {
  static var mockOverlay: Badge {
    .init(
      name: "RainTime",
      id: "01FCY771D800007PQ2DF3GDTN6",
      category: .global,
      source: .seventv,
      overlay: true,
      width: 32,
      height: 32
    )
  }

  static var mock7tv: Badge {
    .init(
      name: "sadEing",
      id: "01J3Q6RTN80004SVBK6PNC1AA8",
      category: .channel,
      source: .seventv,
      overlay: false,
      width: 32,
      height: 32
    )
  }

  static var mocks: [Badge] { [.mockOverlay, .mock7tv] }
}
