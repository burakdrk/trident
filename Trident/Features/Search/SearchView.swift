import SwiftUI

struct SearchView: View {
  @State private var store = SearchStore()
  @Environment(\.router) private var router
  @Environment(\.auth) private var auth

  var body: some View {
    NavigationStack(path: router.searchPath) {
      ZStack {
        SearchRootView(query: store.state.query)
          .navigationTitle("Search")
          .navigationDestination(for: SearchRoute.self) { route in
            route.destination
          }
          .searchable(
            text: store.binding(\.searchText, action: store.setSearchText),
            prompt: auth.state.phase == .loggedIn ? "Search..." : "Enter a channel to join"
          )
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
          .onSubmit(of: .search) {}
      }
      .themedAppBackground()
      .task { await store.startDebounceTask() }
    }
  }
}

#Preview {
  SearchView()
    .applyTheme()
}
