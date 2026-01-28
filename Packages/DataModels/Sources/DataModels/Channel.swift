import Foundation

public struct Channel: Identifiable, Hashable, Sendable {
  public let id: String
  public let loginName: String
  public let displayName: String
  public let avatarURL: URL

  public init(id: String, loginName: String, displayName: String, avatarURL: URL) {
    self.id = id
    self.loginName = loginName
    self.displayName = displayName
    self.avatarURL = avatarURL
  }

  public static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

extension Channel: Mockable {
  public static let mock: Channel = mockList[0]

  public static var mockList: [Channel] {
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
