import DataModels
import SwiftUI

struct StreamManagerView: View {
  @Environment(\.streamManager) private var streamManager

  var body: some View {
    @Bindable var streamManager = streamManager

    GeometryReader { geo in
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: 0) {
          ForEach(streamManager.favoriteChannels, id: \.self) { channel in
            renderStream(for: channel)
              .containerRelativeFrame(.horizontal)
          }
        }
      }
      .scrollTargetLayout()
      .scrollTargetBehavior(.paging)
      .scrollPosition(id: $streamManager.visibleChannel)
      .ignoresSafeArea()
      .themedBackground()
      .environment(\.safeAreaInsets, geo.safeAreaInsets)
    }
  }

  @ViewBuilder
  private func renderStream(for channel: Channel) -> some View {
    if let chatModel = streamManager.activeChannels[channel] {
      StreamView(model: chatModel)
    } else {
      Text("Loading...")
    }
  }
}
