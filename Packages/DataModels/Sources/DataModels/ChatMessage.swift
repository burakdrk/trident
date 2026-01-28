import Foundation

public struct ChatMessage: Identifiable, Hashable, Sendable {
  public struct Author: Hashable, Sendable {
    public let displayName: String
    public let colorHex: String
    public let badges: [String]

    public init(displayName: String, colorHex: String, badges: [String]) {
      self.displayName = displayName
      self.colorHex = colorHex
      self.badges = badges
    }
  }

  public enum Inline: Hashable, Sendable {
    /// Text part of the message
    case text(String)

    /// Emotes in the message, an array for overlay (zero-width) emotes
    case emote([Emote])
  }

  public let id: String
  public let inlines: [Inline]
  public let author: Author
  public let timestamp: Date
  public let rawText: String
  public let historical: Bool

  public init(
    id: String,
    inlines: [Inline],
    author: Author,
    timestamp: Date,
    rawText: String,
    historical: Bool
  ) {
    self.id = id
    self.inlines = inlines
    self.author = author
    self.timestamp = timestamp
    self.rawText = rawText
    self.historical = historical
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

// MARK: - Mock Data

extension ChatMessage: Mockable {
  public static let mock = ChatMessage(
    id: "1",
    inlines: [],
    author: .init(displayName: "forsen", colorHex: "#FFFFFF", badges: []),
    timestamp: .now,
    rawText: "Hi",
    historical: false
  )
}
