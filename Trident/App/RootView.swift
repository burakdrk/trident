import SwiftUI

struct RootView: View {
  @Environment(\.router) private var router

  var body: some View {
    @Bindable var router = router

    TabView(selection: $router.selectedTab) {
      ForEach(RootTab.allCases, id: \.name) { tab in
        Tab(
          tab.name,
          systemImage: tab.imageName(),
          value: tab,
          role: tab == .search ? .search : nil
        ) {
          tab.destination.background(BackgroundHelper())
        }
      }
    }
    .fullScreenCover(item: $router.presentedCover) { $0.destination }
  }
}

#Preview {
  RootView()
    .applyTheme()
}
