//
//  ChatView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-13.
//

import SDWebImage
import SwiftUI

struct ChatView: View {
  @State private var store = ChatStore()

  var body: some View {
    ZStack(alignment: .bottom) {
      ChatViewController(
        messages: store.state.messages,
        isPaused: store.state.isPaused,
        lastUpdateID: store.state.lastUpdateID
      ) { val in
        store.dispatch(.togglePause(val))
      }
      .equatable()

      ScrollButtonView(
        newMessageCount: store.state.newMessageCount,
        isShown: store.state.isPaused
      ) {
        store.dispatch(.togglePause(false))
      }
      .padding(.bottom, 50)
    }
    .task {
      store.dispatch(.start)
    }
  }
}

#Preview {
  let _: Void = SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)

  return ChatView()
    .edgesIgnoringSafeArea(.all)
}
