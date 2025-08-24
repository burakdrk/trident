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

  /// Search Bar Props
  @Binding var searchText: String
  @State private var isSearchExpanded = false
  @State private var lastNonSearchTab: Tabs = .explore
  @FocusState private var isKeyboardActive: Bool

  private let barHeight: CGFloat = 56
  private let barSpacing: CGFloat = 12
  private let shadowRadius: CGFloat = 4

  var body: some View {
    let mainLayout = isKeyboardActive ?
      AnyLayout(ZStackLayout(alignment: .leading)) :
      AnyLayout(HStackLayout(spacing: barSpacing))

    mainLayout {
      HStack(spacing: 0) {
        if isSearchExpanded {
          TabButton(lastNonSearchTab)
            .frame(width: barHeight, height: barHeight)
        } else {
          ForEach(Tabs.allCases.dropLast(), id: \.hashValue) {
            TabButton($0)
          }
        }
      }
      .padding(.horizontal, isSearchExpanded ? 0 : 6)
      .frame(height: barHeight)
      .shadow(radius: shadowRadius)
      .background(TabBarBackground())
      .clipShape(.capsule(style: .continuous))
      .animation(.smooth(duration: 0.35), value: activeTab)
      .opacity(isKeyboardActive ? 0 : 1)

      ExpandableSearchBar()
        .onChange(of: activeTab) { _, new in
          if new != .search { lastNonSearchTab = new }
        }
    }
    .geometryGroup()
    .padding(.horizontal, isKeyboardActive ? 0 : 36)
  }
}

// MARK: - Search

extension FloatingTabBar {
  @ViewBuilder
  private func ExpandableSearchBar() -> some View {
    let searchLayout = isKeyboardActive ?
      AnyLayout(HStackLayout(spacing: barSpacing)) :
      AnyLayout(ZStackLayout(alignment: .trailing))

    searchLayout {
      HStack {
        if isSearchExpanded {
          TextField("Search...", text: $searchText)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .foregroundStyle(theme.fg)
            .focused($isKeyboardActive)
            .frame(height: barHeight)
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .onTapGesture {
              isKeyboardActive = true
            }
        } else {
          TabButton(Tabs.search)
            .frame(width: barHeight, height: barHeight)
        }
      }
      .geometryGroup()
      .zIndex(1)

      // Close Button
      Button {
        searchText = ""
        isKeyboardActive = false
      } label: {
        Image(systemName: "xmark")
          .accessibilityLabel("Close Search")
          .font(.system(size: 20))
          .foregroundStyle(.gray)
          .padding(.trailing, 15)
      }
      .opacity(isKeyboardActive ? 1 : 0)
    }
    .shadow(radius: shadowRadius)
    .background(TabBarBackground())
    .clipShape(isKeyboardActive ? AnyShape(.rect) : AnyShape(.capsule(style: .continuous)))
    .animation(.bouncy, value: isKeyboardActive)
  }
}

// MARK: - Helpers

extension FloatingTabBar {
  private func TabButton(_ tab: Tabs) -> some View {
    let isActive = activeTab == tab
    let isSearch = Tabs.search == tab

    return Button {
      activeTab = tab
      haptics.generate(.impactLight)
      withAnimation(.bouncy) {
        isSearchExpanded = isSearch
      }
    } label: {
      ZStack {
        if isActive, !isSearch {
          Capsule(style: .continuous)
            .fill(accent.color.gradient)
            .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
        } else {
          Capsule(style: .continuous)
            .fill(Color.black.opacity(0.0001))
        }

        Image(systemName: isActive ? tab.activeImageName : tab.imageName)
          .accessibilityLabel("Switch to \(tab.name)")
          .font(.system(size: 24))
          .foregroundStyle(isActive ? .white : .gray)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .buttonStyle(.plain)
    .contentShape(.rect)
    .padding(.vertical, 6)
  }

  private func TabBarBackground() -> some View {
    ZStack {
      Rectangle().fill(.ultraThinMaterial)
      Rectangle().fill(theme.bgElev.opacity(0.8))
    }
    .compositingGroup()
  }
}

#Preview(traits: .sizeThatFitsLayout) {
  FloatingTabBar(activeTab: .constant(.explore), searchText: .constant(""))
}
