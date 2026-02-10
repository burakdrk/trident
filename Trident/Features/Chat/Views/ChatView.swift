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

  private var scrollButton: some View {
    ScrollButton(
      newMessageCount: model.newMessageCount,
      isVisible: model.isPaused
    ) {
      model.setIsPaused(false)
      model.emit(.scrollToBottom)
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
