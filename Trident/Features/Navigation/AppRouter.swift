import SwiftUI

@MainActor
@Observable
final class AppRouter {
  var selectedTab: Tabs = .explore
  var hideTabBar: Bool = false

  var explorePath: [ExploreRoute] = []
  var userPath: [UserRoute] = []
  var searchPath: [SearchRoute] = []
  var followingPath: [FollowingRoute] = []

  private nonisolated init() {}

  func push(to tab: Tabs, _ route: any Route) {
    selectedTab = tab
    switch (tab, route) {
    case let (.explore, r as ExploreRoute): push(r)
    case let (.user, r as UserRoute): push(r)
    case let (.search, r as SearchRoute): push(r)
    case let (.following, r as FollowingRoute): push(r)
    default: assertionFailure("Invalid route for tab \(tab)")
    }
  }

  private func push(_ r: ExploreRoute) { explorePath.append(r) }
  private func push(_ r: UserRoute) { userPath.append(r) }
  private func push(_ r: SearchRoute) { searchPath.append(r) }
  private func push(_ r: FollowingRoute) { followingPath.append(r) }

  func pop(tab: Tabs) {
    switch tab {
    case .explore: _ = explorePath.popLast()
    case .user: _ = userPath.popLast()
    case .search: _ = searchPath.popLast()
    case .following: _ = followingPath.popLast()
    }
  }

  func popToRoot(tab: Tabs) {
    switch tab {
    case .explore: explorePath.removeAll()
    case .user: userPath.removeAll()
    case .search: searchPath.removeAll()
    case .following: followingPath.removeAll()
    }
  }
}

// MARK: - Environment

extension AppRouter {
  nonisolated static let shared = AppRouter()
}

extension EnvironmentValues {
  @Entry var router = AppRouter.shared
}
