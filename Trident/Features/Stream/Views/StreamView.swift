import SwiftUI

struct StreamView: View {
  let model: ChatModel

  var body: some View {
    ChatView(model: model)
  }
}
