import SwiftUI

struct SearchTab: View {
  @State private var store = SearchStore()
  @Environment(\.router) private var router

  var searchText: String

  var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.searchPath) {
      ZStack {
        SearchRootView(text: store.state.query)
          .navigationTitle("Search")
          .navigationDestination(for: SearchRoute.self) { route in
            switch route {
            case .channel(let name):
              ChatRootView(channel: name)
            }
          }
      }
      .themedAppBackground()
      .onChange(of: searchText, initial: true) { _, newValue in
        store.dispatch(.setQuery(newValue))
      }
    }
  }
}

#Preview {
  SearchTab(searchText: "quin69")
    .applyTheme()
}
