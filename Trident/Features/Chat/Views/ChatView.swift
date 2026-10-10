import SwiftUI

struct ChatView: View {
  @Environment(\.safeAreaInsets) private var safeAreaInsets

  let model: ChatModel

  var body: some View {
    ZStack {
      ChatViewController.SwiftUIView(
        model: model
      )

      VStack {
        connectionBanner

        Spacer()

        ZStack {
          HStack {
            Spacer()

            sendButton
              .padding(.trailing)
          }

          scrollButton
        }
      }
      .padding(safeAreaInsets)
      .padding(.bottom)
    }
    .task { await model.startReading() }
    .task { await model.startRendering() }
  }

  @ViewBuilder
  private var connectionBanner: some View {
    switch model.connection {
    case .live:
      EmptyView()
    case .connecting:
      ConnectionBanner(title: "Connecting…")
    case .reconnecting:
      ConnectionBanner(title: "Reconnecting…")
    }
  }

  private var scrollButton: some View {
    ScrollButton(
      newMessageCount: model.newMessageCount,
      isVisible: model.isPaused
    ) {
      model.setIsPaused(false)
    }
  }

  private var sendButton: some View {
    Button {
      print("Sending")
    } label: {
      Image(systemName: "arrow.down.circle.fill")
    }
    .buttonStyle(.primary(shape: .circle))
  }
}

private struct ConnectionBanner: View {
  let title: LocalizedStringKey

  var body: some View {
    HStack(spacing: 8) {
      ProgressView()
      Text(title).font(.footnote)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .glassEffect()
    .transition(.opacity)
  }
}
