//
//  SearchTab.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-19.
//

import SwiftUI

struct SearchTab: View {
  @Environment(\.router) private var router
  @State private var store = SearchStore()

  var searchText: String

  var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.searchPath) {
      VStack {
        SearchRootView(text: store.state.query)
          .navigationTitle("Search")
          .navigationDestination(for: SearchRoute.self) { route in
            switch route {
            case let .channels(query):
              ChatView(channel: query)
            case let .users(query):
              Text(query)
            }
          }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .themedBackground()
      .onChange(of: searchText) { _, newValue in
        store.dispatch(.setQuery(newValue))
      }
    }
  }
}

#Preview {
  SearchTab(searchText: "Preview")
}
