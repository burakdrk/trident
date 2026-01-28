import Foundation

public struct User: Identifiable, Hashable, Sendable {
  private let channel: Channel
  public var id: String { channel.id }

  public init(channel: Channel) {
    self.channel = channel
  }

  public static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
