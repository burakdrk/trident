import SDWebImage
import SwiftUI

struct ChatView: View {
  @State private var store: ChatStore
  @Environment(\.router) private var router

  init(channel: String) {
    _store = State(initialValue: ChatStore(channel: channel))
  }

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
      .padding(.horizontal, 5)
      .ignoresSafeArea(.all)
      .themedBackground()

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

  return ChatView(channel: "xqc")
    .edgesIgnoringSafeArea(.all)
}
