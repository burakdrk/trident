//
//  FloatingTabView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-18.
//

import Foundation
import SwiftUI

struct FloatingTabView<Content: View>: View {
  @Environment(AppRouter.self) private var router
  var content: (Tabs, CGFloat) -> Content

  init(@ViewBuilder content: @escaping (Tabs, CGFloat) -> Content) {
    self.content = content
  }

  @State private var tabBarSize: CGSize = .zero
  @State private var hideTabBar: Bool = false

  var body: some View {
    @Bindable var router = router

    ZStack(alignment: .bottom) {
      TabView(selection: $router.selectedTab) {
        ForEach(Tabs.allCases, id: \.hashValue) { tab in
          Tab(value: tab) {
            content(tab, tabBarSize.height)
              .toolbarVisibility(.hidden, for: .tabBar)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .themedBackground()
          }
        }
      }

      FloatingTabBar(activeTab: $router.selectedTab)
        .padding(.horizontal, 50)
        .padding(.bottom, 5)
        .onGeometryChange(for: CGSize.self) {
          $0.size
        } action: { newValue in
          tabBarSize = newValue
        }
        .offset(y: router.hideTabBar ? (tabBarSize.height + 100) : 0)
        .animation(.smooth(duration: 0.35, extraBounce: 0), value: router.hideTabBar)
    }
  }
}
