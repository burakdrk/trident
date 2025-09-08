import SwiftUI

struct FollowingTab: View {
  @Environment(\.router) private var router

  var body: some View {
    NavigationStack(path: router.followingPath) {
      FollowList()
        .containerBackground(.clear, for: .navigation)
        .navigationTitle("Following")
        .navigationDestination(for: FollowingRoute.self) { $0.destination }
    }
  }
}

#Preview {
  FollowingTab()
    .applyTheme()
}
