import SwiftUI

struct ChatInputBar: View {
  @Environment(\.accent) private var accent
  @Environment(\.theme) private var theme
  @Environment(\.auth) private var auth

  @State private var store = ChatInputModel(initialState: .init(), dependencies: .init())
  @FocusState private var isKeyboardActive: Bool

  let onSend: () async throws -> Void

  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      // Input
      TextField(
        auth.state.isAuthenticated ? "Enter message" : "Log in to send a message",
        text: .init { store.state.text } set: { store.setText($0) },
        axis: .vertical
      )
      .submitScope()
      .lineLimit(1...10)
      .autocorrectionDisabled()
      .textInputAutocapitalization(.never)
      .textFieldStyle(.plain)
      .focused($isKeyboardActive)
      .padding(12)
      .background(theme.bgElev, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
      .themedForeground()
      .disabled(!auth.state.isAuthenticated)

      // Send
      Button {
        store.sendIfNeeded(onSend)
      } label: {
        Image(systemName: "paperplane.fill")
          .font(.system(size: 22, weight: .semibold))
          .rotationEffect(.degrees(45))
      }
      .disabled(store.state.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store
        .state
        .isSending
      )
      .padding(.horizontal, 2)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .glassEffect()
    .padding(.horizontal, 16)
  }
}

#Preview {
  ChatInputBar {}
    .applyTheme()
}
