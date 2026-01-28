import Alamofire
import SDWebImage
import SwiftUI

@main
struct TridentApp: App {
  @State private var appRouter = AppRouter.shared
  @State private var themeManager = ThemeManager.shared
  @State private var auth = AuthStore.shared
  @State private var streamManager = StreamStore.shared

  init() {
    SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)
  }

  var body: some Scene {
    WindowGroup {
      contentView
        .applyTheme()
        .environment(\.router, appRouter)
        .environment(\.themeManager, themeManager)
        .environment(\.auth, auth)
        .environment(\.streamManager, streamManager)
        .task { await auth.startEventListener() }
        .task { await auth.loadSession() }
        .task { await auth.startHourlyValidation() }
    }
  }

  private var contentView: some View {
    TabView(selection: $appRouter.selectedTab) {
      ForEach(AppTab.allCases, id: \.hashValue) { tab in
        Tab(
          tab.name,
          systemImage: tab.imageName(),
          value: tab,
          role: tab == .search ? .search : nil
        ) {
          tab.destinationView
            .background(BackgroundHelper())
        }
      }
    }
  }

//  private var contentView2: some View {
//    TabView(selection: $appRouter.selectedTab) {
//      Tab(
//        tab.name,
//        systemImage: tab.imageName(),
//        value: tab,
//        role: tab == .search ? .search : nil
//      ) {
//        tab.destinationView
//          .background(BackgroundHelper())
//      }
//    }
//  }
}

// MARK: - Network Setup

let AF = Alamofire.Session(eventMonitors: [])
