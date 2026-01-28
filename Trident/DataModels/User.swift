import Foundation

struct User: Identifiable, Hashable, Sendable {
  private let channel: Channel
  var id: String { channel.id }

  static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
