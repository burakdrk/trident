//
//  TridentApp.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-23.
//

import SDWebImage
import SDWebImageSVGNativeCoder
import SwiftUI

@main
struct TridentApp: App {
  @State private var appRouter = AppRouter.shared
  @State private var themeManager = ThemeManager.shared
  @State private var auth = AuthStore.shared

  init() {
    SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)
    SDImageCodersManager.shared.addCoder(SDImageSVGNativeCoder.shared)

    auth.dispatch(.loadSession)
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .applyTheme()
        .environment(\.router, appRouter)
        .environment(\.themeManager, themeManager)
        .environment(\.auth, auth)
        .task { auth.dispatch(.startHourlyValidation) }
    }
  }
}
