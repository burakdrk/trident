//
//  ScrollButtonView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import SwiftUI

struct ScrollButtonView: View {
  let action: () -> Void
  let viewModel: ScrollButtonViewModel

  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: "arrow.down.circle.fill")

        if viewModel.newMessageCount != 0 {
          Text(
            "\(String(viewModel.newMessageCount)) new message\(viewModel.newMessageCount == 1 ? "" : "s")"
          )
        } else {
          Text("Auto-scroll")
        }
      }
      .font(.callout.bold())
      .padding(12)
      .background(Color.accentColor)
      .foregroundColor(.white)
      .clipShape(Capsule())
    }
    .allowsHitTesting(viewModel.isShown)
    .opacity(viewModel.isShown ? 1 : 0)
    .buttonStyle(.scale())
  }
}

#Preview(traits: .sizeThatFitsLayout) {
  ScrollButtonView(action: {}, viewModel: ScrollButtonViewModel())
}
