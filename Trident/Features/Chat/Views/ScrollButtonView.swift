//
//  ScrollButtonView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import SwiftUI

struct ScrollButtonView: View {
    let action: () -> Void
    let vm: ScrollButtonViewModel

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")

                vm.newMessageCount != 0 ?
                    Text("\(String(vm.newMessageCount)) new message\(vm.newMessageCount == 1 ? "" : "s")")
                    : Text("Auto-scroll")
            }
            .font(.callout.bold())
            .padding(12)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .allowsHitTesting(vm.isShown)
        .opacity(vm.isShown ? 1 : 0)
        .buttonStyle(.scale())
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ScrollButtonView(action: {}, vm: ScrollButtonViewModel())
}
