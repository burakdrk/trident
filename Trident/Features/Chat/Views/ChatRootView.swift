import SDWebImage
import SwiftUI

struct ChatRootView: View {
  @State private var store = ChatStore()
  @Environment(\.router) private var router

  var channelName: String

  var body: some View {
    ZStack(alignment: .bottom) {
      GeometryReader { geo in
        ChatView(
          store: store,
          bottomInset: geo.safeAreaInsets.bottom
        )
        .padding(.horizontal, 5)
        .ignoresSafeArea(.all)
        .themedBackground()
      }

      ScrollButton(
        newMessageCount: store.state.newMessageCount,
        isVisible: store.state.isPaused
      ) {
        store.dispatch(.togglePause(false))
      }
      .padding(.bottom, 20)
    }
    .toolbar(.hidden, for: .tabBar)
    .apply {
      if #available(iOS 26.0, *) {
        $0.safeAreaBar(edge: .bottom, spacing: 0) {
          ChatInputBar {}
        }
      } else {
        $0.safeAreaInset(edge: .bottom, spacing: 0) {
          ChatInputBar {}
        }
      }
    }
  }
}

#Preview {
  let _: Void = SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)
  return ChatRootView(channelName: "xqc")
}
