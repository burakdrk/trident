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
  var selectedTab: Tabs = .top
  var hideTabBar: Bool = false

  var topPath: [TopRoute] = []
  var userPath: [UserRoute] = []

  // Push
  func push(_ r: TopRoute) { topPath.append(r) }
  func push(_ r: UserRoute) { userPath.append(r) }

  // Pop
  func pop(tab: Tabs) {
    switch tab {
    case .top: _ = topPath.popLast()
    case .user: _ = userPath.popLast()
    default: break
    }
  }

  func popToRoot(tab: Tabs) {
    switch tab {
    case .top: topPath.removeAll()
    case .user: userPath.removeAll()
    default: break
    }
  }
}
