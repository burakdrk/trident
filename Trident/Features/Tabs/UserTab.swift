//
//  UserTab.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-23.
//

import SwiftUI

struct UserTab: View {
  @Environment(\.router) private var router

  var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.userPath) {
      VStack {
        Text("User")
          .navigationTitle("User")
      }
      .authBoundary()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .themedBackground()
    }
  }
}

#Preview {
  UserTab()
}
