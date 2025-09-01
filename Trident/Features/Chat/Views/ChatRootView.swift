import SDWebImage
import SwiftUI

struct ChatRootView: View {
  @State private var store: ChatStore
  @Environment(\.router) private var router

  init(channel: String) {
    _store = State(initialValue: ChatStore(channel: channel))
  }

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
    .task { store.dispatch(.start) }
    .onDisappear { store.dispatch(.stop) }
    .hideFloatingTabBar()
    .navigationTitle(store.state.channel)
    .toolbarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden()
    .toolbarBackgroundVisibility(.visible, for: .navigationBar)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button {
          router.pop(tab: .search)
        } label: {
          Image(systemName: "chevron.left")
        }
      }
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      ChatInputBar {}
    }
  }
}

#Preview {
  let _: Void = SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)

  return ChatRootView(channel: "xqc")
    .edgesIgnoringSafeArea(.all)
}
