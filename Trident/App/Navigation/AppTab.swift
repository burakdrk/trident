import SwiftUI

enum AppTab: CaseIterable, Hashable {
  case following
  case explore
  case user
  case search

  var destinationView: some View {
    AppTabContent(appTab: self)
  }

  var name: LocalizedStringResource {
    switch self {
    case .following:
      .followingTab
    case .explore:
      .exploreTab
    case .search:
      .searchTab
    case .user:
      .userTab
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

struct AppTabContent: View {
  @Environment(\.router) private var router

  let appTab: AppTab

  var body: some View {
    NavigationStack(path: router.path(for: appTab)) {
      Group {
        switch appTab {
        case .following:
          FollowList()
        case .explore:
          EmptyView()
        case .user:
          EmptyView()
        case .search:
          SearchView()
        }
      }
      .navigationDestination(for: AnyRoute.self) { route in
        route.destinationView()
      }
      .toolbarBackground(.thinMaterial, for: .tabBar)
      .toolbarBackgroundVisibility(.visible, for: .tabBar)
      .containerBackground(.clear, for: .navigation)
    }
  }
}
