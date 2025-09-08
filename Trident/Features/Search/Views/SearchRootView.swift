import SwiftUI

struct SearchRootView: View {
  @Environment(\.router) private var router
  @Environment(\.auth) private var auth

  var query = ""

  var body: some View {
    Button {
      router.pushToSearch(.channel(name: query.lowercased()))
    } label: {
      Text("Go to \(query)")
    }
  }
}

#Preview {
  SearchRootView()
    .applyTheme()
}
