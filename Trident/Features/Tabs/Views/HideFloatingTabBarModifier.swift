//
//  HideFloatingTabBarModifier.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-18.
//

import SwiftUI

struct HideFloatingTabBarModifier: ViewModifier {
  var status: Bool
  @Environment(\.router) private var router

  func body(content: Content) -> some View {
    content
      .onChange(of: status, initial: true) { _, newValue in
        router.hideTabBar = newValue
      }
      .onDisappear {
        router.hideTabBar = false
      }
  }
}

extension View {
  func hideFloatingTabBar(_ status: Bool = true) -> some View {
    modifier(HideFloatingTabBarModifier(status: status))
  }
}
