import SwiftUI

struct SearchView: View {
  @State private var store = SearchModel(initialState: .init(), dependencies: .init())

  @Environment(\.auth) private var auth

  var body: some View {
    Button {
      // router.push(to: .search, ChatRootView(channelName: store.state.query.lowercased()))
    } label: {
      Text("Go to \(store.state.query)")
    }
    .navigationTitle("Search")
    .searchable(
      text: store.binding(\.searchText) { newValue in
        Task { await store.dependencies.changes.send(newValue) }
      },
      prompt: auth.state.phase == .loggedIn ? "Search..." : "Enter a channel to join"
    )
    .autocorrectionDisabled()
    .textInputAutocapitalization(.never)
    .onSubmit(of: .search) {}
    .task { await store.startDebounceTask() }
  }
}
