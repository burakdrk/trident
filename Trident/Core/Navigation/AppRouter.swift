//
//  AppRouter.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-17.
//

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

  // Push
  func push(_ r: ExploreRoute) { explorePath.append(r) }
  func push(_ r: UserRoute) { userPath.append(r) }
  func push(_ r: SearchRoute) { searchPath.append(r) }
  func push(_ r: FollowingRoute) { followingPath.append(r) }

  // Pop
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
  nonisolated static let live = AppRouter()
}

extension EnvironmentValues {
  @Entry var router = AppRouter.live
}
