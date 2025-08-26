//
//  SearchRootView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-19.
//

import SwiftUI

struct SearchRootView: View {
  @Environment(\.router) private var router
  @Environment(\.auth) private var auth

  var text = ""

  var body: some View {
    Button {
      router.push(.channel(name: text))
    } label: {
      Text("Go to \(text)")
    }
    .if(auth.state.phase == .loggedOut) { view in
      view.onReceive(NotificationCenter.default.publisher(for: .searchSubmitted)) { notification in
        if let userInfo = notification.userInfo, let text = userInfo["text"] as? String {
          router.push(.channel(name: text))
        }
      }
    }
  }
}

#Preview {
  SearchRootView()
    .applyTheme()
}
