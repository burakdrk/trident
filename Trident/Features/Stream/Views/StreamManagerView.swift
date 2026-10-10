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
    } else if let failure = streamManager.loadFailures[channel] {
      LoadFailureView(channel: channel, message: failure)
    } else {
      Text("Loading...")
    }
  }
}

private struct LoadFailureView: View {
  @Environment(\.streamManager) private var streamManager

  let channel: Channel
  let message: String

  /// Bumped by the button. Changing the id restarts the task, which is how a retry runs inside
  /// the view's lifetime.
  @State private var attempt = 0

  var body: some View {
    VStack(spacing: 12) {
      Text("Couldn't open \(channel.displayName)").font(.headline)
      Text(message).font(.footnote).foregroundStyle(.secondary)

      Button("Try again") { attempt += 1 }
        .buttonStyle(.primary(color: .twitchPurple))
    }
    .padding()
    .task(id: attempt) {
      guard attempt > 0 else { return }
      await streamManager.loadStream(for: channel)
    }
  }
}
