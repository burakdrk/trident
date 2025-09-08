import SDWebImage
import SwiftUI

@main
struct TridentApp: App {
  @State private var appRouter = AppRouter.shared
  @State private var themeManager = ThemeManager.shared
  @State private var auth = AuthStore.shared

  init() {
    SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .applyTheme()
        .environment(\.router, appRouter)
        .environment(\.themeManager, themeManager)
        .environment(\.auth, auth)
        .task { await auth.startEventListener() }
        .task { await auth.loadSession() }
        .task { await auth.startHourlyValidation() }
    }
  }
}
