//
//  TridentApp.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-23.
//

import SDWebImage
import SwiftUI

@main
struct TridentApp: App {
  @State private var appRouter = AppRouter()
  @State private var themeManager = ThemeManager()

  init() {
    SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .applyTheme()
        .environment(appRouter)
        .environment(themeManager)
    }
  }
}
