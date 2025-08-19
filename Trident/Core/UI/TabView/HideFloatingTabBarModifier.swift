//
//  HideFloatingTabBarModifier.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-18.
//

import SwiftUI

struct HideFloatingTabBarModifier: ViewModifier {
  var status: Bool
  @Environment(AppRouter.self) private var router

  func body(content: Content) -> some View {
    content
      .onChange(of: status, initial: true) { _, newValue in
        router.hideTabBar = newValue
      }
  }
}

extension View {
  func hideFloatingTabBar(_ status: Bool) -> some View {
    modifier(HideFloatingTabBarModifier(status: status))
  }
}
