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
            case let .channel(name):
              ChatView(channel: name)
            }
          }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .themedBackground()
      .onChange(of: searchText, initial: true) { _, newValue in
        store.dispatch(.setQuery(newValue))
      }
    }
  }
}

#Preview {
  SearchTab(searchText: "xqc")
    .applyTheme()
}
