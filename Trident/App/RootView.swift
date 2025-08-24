//
//  RootView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-28.
//

import Dependencies
import SwiftUI

struct RootView: View {
  var body: some View {
    FloatingTabView { tab, _, search in
      switch tab {
      case .following: FollowingTab()
      case .explore: ExploreTab()
      case .user: UserTab()
      case .search: SearchTab(searchText: search)
      }
    }
  }
}

#Preview {
  RootView()
    .applyTheme()
}
