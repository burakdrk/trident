import Foundation

public struct User: Identifiable, Hashable, Sendable {
  public let id: String
  public let loginName: String
  public let displayName: String
  public let isLoggedIn: Bool // Whether this user is the logged-in user
  public let avatarURL: URL
  public var viewCount: Int = 0

  public static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

extension User: Mockable {
  public static var mock: User {
    mockList[0]
  }

  public static var mockList: [User] {
    [
      User(
        id: "22484632",
        loginName: "forsen",
        displayName: "forsen",
        isLoggedIn: false,
        avatarURL: URL.make(
          "https://static-cdn.jtvnw.net/jtv_user_pictures/forsen-profile_image-48b43e1e4f54b5c8-300x300.png"
        ),
        viewCount: 4_000
      ),
      User(
        id: "71092938",
        loginName: "xqc",
        displayName: "xQc",
        isLoggedIn: false,
        avatarURL: URL.make(
          "https://static-cdn.jtvnw.net/jtv_user_pictures/xqc-profile_image-9298dca608632101-300x300.jpeg"
        ),
        viewCount: 12_000
      )
    ]
  }
}
