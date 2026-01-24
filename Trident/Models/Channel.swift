import Foundation

@dynamicMemberLookup
struct Channel: Identifiable, Hashable, Sendable {
  private let user: User
  var id: String { user.id }
  var emotes: [String: Emote] = [:]

  subscript<T>(dynamicMember keyPath: KeyPath<User, T>) -> T {
    user[keyPath: keyPath]
  }

  static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

extension Channel: Mockable {
  static var mock: Channel {
    Channel(user: .mock)
  }

  static var mockList: [Channel] {
    User.mockList.map { .init(user: $0) }
  }
}
