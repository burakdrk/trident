import SwiftUI

enum RootTab: CaseIterable, Hashable {
  case following
  case explore
  case user
  case search

  @MainActor
  @ViewBuilder var destination: some View {
    Group {
      switch self {
      case .following:
        FollowingTab()
      case .explore:
        EmptyView()
      case .user:
        EmptyView()
      case .search:
        SearchView()
      }
    }
    .toolbarBackground(.thinMaterial, for: .tabBar)
    .toolbarBackgroundVisibility(.visible, for: .tabBar)
  }

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

  func imageName(active: Bool = true) -> String {
    switch self {
    case .following:
      active ? "heart.fill" : "heart"
    case .explore:
      active ? "safari.fill" : "safari"
    case .search:
      "magnifyingglass"
    case .user:
      active ? "person.fill" : "person"
    }
  }
}
