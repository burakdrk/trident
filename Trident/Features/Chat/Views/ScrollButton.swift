//
//  ScrollButton.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import SwiftUI
import UIKit

struct ScrollButton: View {
  let newMessageCount: Int
  let isVisible: Bool
  let action: () -> Void

  @State private var isAnimating = false
  @State private var frozenMessageCount: Int?

  private var displayedMessageCount: Int {
    isAnimating ? (frozenMessageCount ?? newMessageCount) : newMessageCount
  }

  var body: some View {
    Button {
      haptics.generate(.impactLight)
      frozenMessageCount = newMessageCount
      isAnimating = true
      withAnimation(.easeInOut(duration: 0.2)) {
        action()
      } completion: {
        isAnimating = false
        frozenMessageCount = nil
      }
    } label: {
      HStack {
        Image(systemName: "arrow.down.circle.fill")

        if newMessageCount != 0 {
          Text(
            "\(String(newMessageCount)) new message\(newMessageCount == 1 ? "" : "s")"
          )
        } else {
          Text("Auto-scroll")
        }
      }
      .accessibilityLabel("Scroll to new messages")
    }
    .allowsHitTesting(isVisible)
    .opacity(isVisible ? 1 : 0)
    .buttonStyle(.primary(color: nil, shape: .capsule))
  }
}

#Preview(traits: .sizeThatFitsLayout) {
  @Previewable @State var isVisible = true
  @Previewable @State var newMessageCount = 0

  ScrollButton(newMessageCount: newMessageCount, isVisible: isVisible) {
    isVisible = false
  }

  Button {
    isVisible = true
    newMessageCount = 0
  } label: {
    Text("Show Scroll Button")
  }
  .opacity(isVisible ? 0 : 1)
  .task {
    while true {
      try? await Task.sleep(for: .seconds(0.5))
      guard isVisible else { continue }
      newMessageCount += Int.random(in: 0 ... 10)
    }
  }
}
