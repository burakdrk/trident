import Foundation

@dynamicMemberLookup
public struct Channel: Identifiable, Hashable, Sendable {
  private let user: User
  public var id: String { user.id }
  public var emotes: [String: Emote] = [:]

  public subscript<T>(dynamicMember keyPath: KeyPath<User, T>) -> T {
    user[keyPath: keyPath]
  }

  public static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

extension Channel: Mockable {
  public static var mock: Channel {
    Channel(user: .mock)
  }

  public static var mockList: [Channel] {
    User.mockList.map { .init(user: $0) }
  }
}
