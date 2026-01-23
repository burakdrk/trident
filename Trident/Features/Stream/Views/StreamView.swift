import SwiftUI

struct StreamView: @MainActor Routable {
  let initialChannel: Channel
  let channels: [Channel]
  let animation: Namespace.ID

  var id: String { makeIdentity(initialChannel, channels, animation) }

  @Environment(\.streamManager) private var streamManager

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 0) {
        ForEach(channels, id: \.self) { channel in
          renderStream(for: channel)
            .containerRelativeFrame(.horizontal)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: streamManager.binding(\.visibleChannel))
    .scrollIndicators(.hidden)
    .onAppear {
      streamManager.update { $0.visibleChannel = initialChannel }
    }
    .task(id: streamManager.visibleChannel) {
      guard let channel = streamManager.visibleChannel else { return }
      await streamManager.loadStream(for: channel)
    }
    .navigationTransition(.zoom(
      sourceID: streamManager.visibleChannel ?? initialChannel,
      in: animation
    ))
  }

  @ViewBuilder
  private func renderStream(for channel: Channel) -> some View {
    if let chatStore = streamManager.activeChannels[channel] {
      ChatRootView(store: chatStore)
    } else {
      Text("Loading...")
    }
  }
}
