import Foundation

struct Channel: Identifiable, Hashable, Sendable {
  let user: User
  var id: String { user.id }
  static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
