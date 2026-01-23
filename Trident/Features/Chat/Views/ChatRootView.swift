import SDWebImage
import SwiftUI

struct ChatRootView: @MainActor Routable {
  @Environment(\.router) private var router
  @Environment(\.streamManager) private var streamManager

  let store: ChatStore
  var id: AnyHashable { store.dependencies.channel }

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
        store.togglePause(false)
      }
      .padding(.bottom, 20)
    }
    .task { await store.startReading() }
    .task { await store.startRendering() }
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
