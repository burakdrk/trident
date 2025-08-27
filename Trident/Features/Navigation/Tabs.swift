import Foundation

enum Tabs: CaseIterable, Hashable {
  case following
  case explore
  case user
  case search

  var name: String {
    switch self {
    case .following:
      "Following"
    case .explore:
      "Explore"
    case .search:
      "Search"
    case .user:
      "User"
    }
  }

  var imageName: String {
    switch self {
    case .following:
      "heart"
    case .explore:
      "safari"
    case .search:
      "magnifyingglass"
    case .user:
      "person"
    }
  }

  var activeImageName: String {
    if self == .search {
      return imageName
    }

    return "\(imageName).fill"
  }

  var index: Int {
    Self.allCases.firstIndex(of: self) ?? 0
  }
}
