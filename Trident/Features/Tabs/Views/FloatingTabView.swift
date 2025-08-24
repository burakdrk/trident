//
//  FloatingTabView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-18.
//

import Foundation
import SwiftUI

struct FloatingTabView<Content: View>: View {
  @Environment(\.router) private var router
  var content: (Tabs, CGFloat, String) -> Content

  init(@ViewBuilder content: @escaping (Tabs, CGFloat, String) -> Content) {
    self.content = content
  }

  @State private var tabBarSize: CGSize = .zero
  @State private var hideTabBar: Bool = false
  @State private var searchText = ""

  var body: some View {
    @Bindable var router = router

    ZStack(alignment: .bottom) {
      TabView(selection: $router.selectedTab) {
        ForEach(Tabs.allCases, id: \.hashValue) { tab in
          Tab(value: tab) {
            content(tab, tabBarSize.height, searchText)
              .toolbarVisibility(.hidden, for: .tabBar)
          }
        }
      }

      FloatingTabBar(activeTab: $router.selectedTab, searchText: $searchText)
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

#Preview {
  FloatingTabView { tab, _, _ in
    Text(tab.name)
  }
  .applyTheme()
}
