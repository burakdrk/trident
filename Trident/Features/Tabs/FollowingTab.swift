//
//  FollowingTab.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-23.
//

import SwiftUI

struct FollowingTab: View {
  @Environment(\.router) private var router

  var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.followingPath) {
      VStack {
        Text("Following")
          .navigationTitle("Following")
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .themedBackground()
    }
  }
}

#Preview {
  FollowingTab()
}
