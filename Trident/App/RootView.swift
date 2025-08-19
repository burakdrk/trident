//
//  RootView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-28.
//

import SwiftUI

struct RootView: View {
  var body: some View {
    FloatingTabView { tab, _ in
      switch tab {
      case .following: Text("Follows")
      case .top: Text("Top")
      case .user: Text("User")
      case .search: Text("Search")
      }
    }
  }
}

#Preview {
  RootView()
    .applyTheme()
    .environment(AppRouter())
    .environment(ThemeManager())
}
