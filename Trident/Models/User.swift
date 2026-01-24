import Foundation

struct User: Identifiable, Hashable, Sendable {
  let id: String
  let loginName: String
  let displayName: String
  let isLoggedIn: Bool // Whether this user is the logged-in user
  let avatarURL: URL
  var viewCount: Int = 0

  static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

extension User: Mockable {
  static var mock: User {
    mockList[0]
  }

  static var mockList: [User] {
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
