import Foundation

struct User: Identifiable, Hashable, Sendable {
  let id: String
  let loginName: String
  let displayName: String
  let isLoggedIn: Bool // Whether this user is the logged-in user

  var avatarURL: URL {
    guard let url = URL(
      string: "https://static-cdn.jtvnw.net/jtv_user_pictures/\(id)-profile_image-300x300.png"
    ) else { fatalError("Invalid avatar URL") }

    return url
  }

  static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
