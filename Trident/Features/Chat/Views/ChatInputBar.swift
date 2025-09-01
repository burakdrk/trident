import SwiftUI

struct ChatInputBar: View {
  @State private var store = ChatInputStore()
  @FocusState private var isKeyboardActive: Bool

  @Environment(\.accent) private var accent
  @Environment(\.theme) private var theme
  @Environment(\.auth) private var auth

  var onSend: @MainActor () async throws -> Void

  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      // Input
      TextField(
        auth.state.isAuthenticated ? "Enter message" : "Log in to send a message",
        text: $store.state.text,
        axis: .vertical
      )
      .submitScope()
      .lineLimit(1...10)
      .autocorrectionDisabled()
      .textInputAutocapitalization(.never)
      .textFieldStyle(.plain)
      .focused($isKeyboardActive)
      .padding(12)
      .background(Color(theme.bgElev), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
      .themedForeground()
      .disabled(!auth.state.isAuthenticated)

      // Send
      Button {
        store.dispatch(.sendIfNeeded(onSend))
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
    .apply {
      if #available(iOS 26.0, *) {
        $0.glassEffect(.regular)
          .padding(.horizontal, 20)
      } else {
        $0.background(.ultraThinMaterial)
      }
    }
  }
}

#Preview {
  ChatInputBar {}
    .applyTheme()
}
