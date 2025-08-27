import SwiftUI

struct SearchRootView: View {
  @Environment(\.router) private var router
  @Environment(\.auth) private var auth

  var text = ""

  var body: some View {
    Button {
      router.push(to: .search, SearchRoute.channel(name: text))
    } label: {
      Text("Go to \(text)")
    }
    .if(auth.state.phase == .loggedOut) { view in
      view.onReceive(NotificationCenter.default.publisher(for: .searchSubmitted)) { notification in
        if let userInfo = notification.userInfo, let text = userInfo["text"] as? String {
          router.push(to: .search, SearchRoute.channel(name: text))
        }
      }
    }
  }
}

#Preview {
  SearchRootView()
    .applyTheme()
}
