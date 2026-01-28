import Foundation

struct Channel: Identifiable, Hashable, Sendable {
  let id: String
  let loginName: String
  let displayName: String
  let avatarURL: URL

  static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

extension Channel: Mockable {
  static let mock: Channel = mockList[0]

  static var mockList: [Channel] {
    [
      Channel(
        id: "22484632",
        loginName: "forsen",
        displayName: "forsen",
        avatarURL: URL.make(
          "https://static-cdn.jtvnw.net/jtv_user_pictures/forsen-profile_image-48b43e1e4f54b5c8-300x300.png"
        )
      ),
      Channel(
        id: "71092938",
        loginName: "xqc",
        displayName: "xQc",
        avatarURL: URL.make(
          "https://static-cdn.jtvnw.net/jtv_user_pictures/xqc-profile_image-9298dca608632101-300x300.jpeg"
        )
      )
    ]
  }
}
