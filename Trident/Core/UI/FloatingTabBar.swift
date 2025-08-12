//
//  FloatingTabBar.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-30.
//

import SwiftUI

struct FloatingTabBar: View {
  @State private var selectedIndex: Int = 0

  let icons = ["heart.fill", "calendar", "magnifyingglass", "person.fill"]

  var body: some View {
    HStack(spacing: 50) {
      ForEach(0 ..< icons.count, id: \.self) { index in
        Button {
          haptics.generate(.impactLight)
          selectedIndex = index
        } label: {
          Image(systemName: icons[index])
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(selectedIndex == index ? .accent : .gray)
            .frame(width: 36.0, height: 36)
            .background(
              Circle()
                .fill(
                  selectedIndex == index
                    ? Color.accentColor.opacity(0.1) : Color.clear
                )
            )
        }
        .buttonStyle(.scale(amount: 0.8))
      }
    }
    .padding(.horizontal, 30)
    .padding(.vertical, 12)
    .background(Color.black)
    .clipShape(Capsule())
  }
}

#Preview(traits: .sizeThatFitsLayout) {
  FloatingTabBar()
}
