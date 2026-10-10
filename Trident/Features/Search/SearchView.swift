import SwiftUI

struct SearchView: View {
  @State private var model = SearchModel()

  @Environment(\.auth) private var auth

  var body: some View {
    @Bindable var model = model

    Button {
      // router.push(to: .search, ChatRootView(channelName: model.query.lowercased()))
    } label: {
      Text("Go to \(model.query)")
    }
    .navigationTitle("Search")
    .searchable(
      text: $model.searchText,
      prompt: auth.phase == .loggedIn ? "Search..." : "Enter a channel to join"
    )
    .autocorrectionDisabled()
    .textInputAutocapitalization(.never)
    .onSubmit(of: .search) {}
    .task(id: model.searchText) { await model.updateQuery() }
  }
}
