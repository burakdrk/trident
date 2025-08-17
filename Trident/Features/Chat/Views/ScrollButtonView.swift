//
//  ScrollButtonView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import SwiftUI
import UIKit

struct ScrollButtonView: View {
  let newMessageCount: Int
  let isShown: Bool
  let action: () -> Void

  var body: some View {
    Button {
      haptics.generate(.impactLight)
      action()
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
      .font(.callout.bold())
      .padding(12)
      .accessibilityLabel("Scroll to new messages")
      .background(Color.accentColor)
      .foregroundColor(.white)
      .clipShape(Capsule())
    }
    .allowsHitTesting(isShown)
    .opacity(isShown ? 1 : 0)
    .buttonStyle(.scale())
  }
}

#Preview(traits: .sizeThatFitsLayout) {
  ScrollButtonView(newMessageCount: 0, isShown: true) {}
}
