import SDWebImage
import SwiftUI

@main
struct TridentApp: App {
  @State private var appRouter = AppRouter()
  @State private var themeManager = ThemeManager()
  @State private var auth = AuthModel()
  @State private var streamManager = StreamManagerModel()

  init() {
    SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)
  }

  var body: some Scene {
    WindowGroup {
      contentView
        .applyTheme()
        .environment(appRouter)
        .environment(themeManager)
        .environment(auth)
        .environment(streamManager)
        // Registering app-level tasks here:
        .task { await auth.startEventListener() }
        .task { await auth.loadSession() }
        .task { await auth.startHourlyValidation() }
        .task(id: streamManager.visibleChannel) {
          guard let channel = streamManager.visibleChannel else { return }
          await streamManager.loadStream(for: channel)
        }
        .task { await streamManager.startIdleStreamCleanup() }
    }
  }

  private var contentView: some View {
    TabView(selection: $appRouter.selectedTab) {
      ForEach(AppRouter.Tab.allCases, id: \.hashValue) { tab in
        Tab(
          tab.name,
          systemImage: tab.imageName(),
          value: tab,
          role: tab == .search ? .search : nil
        ) {
          tab.destinationView(router: appRouter)
            .background(TabViewBackgroundHelper())
        }
      }
    }
    .fullScreenCover(item: $appRouter.streamRouter) { router in
      StreamRouterView(router: router)
    }
  }
}
