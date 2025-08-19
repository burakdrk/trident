//
//  FloatingTabBar.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-30.
//

import Foundation
import SwiftUI

struct FloatingTabBar: View {
  @Environment(\.accent) private var accent
  @Environment(\.theme) private var theme

  @Namespace private var animation

  @Binding var activeTab: Tabs
  @State private var hapticsTrigger: Bool = false
  @State private var toggleSymbolEffect: [Bool] = Array(
    repeating: false,
    count: Tabs.allCases.count
  )

  var body: some View {
    HStack(spacing: 0) {
      ForEach(Tabs.allCases, id: \.hashValue) { self.tabImage($0) }
    }
    .padding(.horizontal, 6)
    .frame(height: 48)
    .background {
      ZStack {
        Rectangle()
          .fill(.ultraThinMaterial)

        Rectangle()
          .fill(theme.bgElev.opacity(0.8))
      }
    }
    .clipShape(.capsule(style: .continuous))
    .shadow(radius: 4)
    .animation(.smooth(duration: 0.35, extraBounce: 0), value: activeTab)
    .sensoryFeedback(.impact, trigger: hapticsTrigger)
  }
}

extension FloatingTabBar {
  private func tabImage(_ tab: Tabs) -> some View {
    let isActive = activeTab == tab
    let index = (Tabs.allCases.firstIndex(of: tab)) ?? 0

    return Image(systemName: isActive ? tab.activeImageName : tab.imageName)
      .font(.title2)
      .foregroundStyle(isActive ? .white : .gray)
      .symbolEffect(.bounce.byLayer.down, value: toggleSymbolEffect[index])
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .contentShape(.rect)
      .background {
        if isActive {
          Capsule(style: .continuous)
            .fill(accent.color.gradient)
            .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
        }
      }
      .onTapGesture {
        activeTab = tab
        toggleSymbolEffect[index].toggle()
        hapticsTrigger.toggle()
      }
      .padding(.vertical, 6)
  }
}
