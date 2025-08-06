//
//  ScrollButtonView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import SwiftUI

struct ScrollButtonView: View {
    let action: () -> Void
    let newMessageCount: Int

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")

                newMessageCount != 0 ?
                    Text("\(String(newMessageCount)) new message\(newMessageCount == 1 ? "" : "s")")
                    : Text("Auto-scroll")
            }
            .font(.callout.bold())
            .padding(10)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .padding(.bottom, 10)
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ScrollButtonView(action: {}, newMessageCount: 1000)
}
