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
  init() {
    SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)
  }

  var body: some Scene {
    WindowGroup {
      ChatView()
        .edgesIgnoringSafeArea(.all)
    }
  }
}
