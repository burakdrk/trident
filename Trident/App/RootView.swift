//
//  RootView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-28.
//

import SwiftUI

struct RootView: View {
  @State private var token: String?
  @State private var isFetchDone: Bool = false
  #if PLUS
    @State private var tokenManager = GQLTokenManager(storage: TokenStorageService())
  #endif

  var body: some View {
    TabView {
      NavigationStack {
        VStack {
          if !isFetchDone {
            Text("Fetching...")
          }

          if let token = token {
            Text("Token received:\n\(token)")
          } else {
            Text("Couldn't get token...")
          }
        }
        .padding()
        .background(.red)
        .frame(maxHeight: .infinity)
        .task {
          #if PLUS
            if let token = try? await tokenManager.getToken() {
              self.token = token.value
              self.isFetchDone = true
            }
          #endif
        }
      }
    }
    .overlay(alignment: .bottom) {
      FloatingTabBar().transition(.offset(y: 300))
    }
  }
}

#Preview {
  RootView()
}
