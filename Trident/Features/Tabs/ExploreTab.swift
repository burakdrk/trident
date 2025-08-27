import SwiftUI

struct ExploreTab: View {
  @Environment(\.router) private var router

  var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.explorePath) {
      VStack {
        Text("Explore")
          .navigationTitle("Explore")
      }
      .authBoundary()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .themedBackground()
    }
  }
}

#Preview {
  ExploreTab()
}
