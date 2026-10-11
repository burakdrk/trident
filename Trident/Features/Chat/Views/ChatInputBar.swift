import SwiftUI

struct ChatInputBar: View {
  @Environment(\.accent) private var accent
  @Environment(\.theme) private var theme
  @Environment(AuthModel.self) private var auth

  @State private var model = ChatInputModel()
  @FocusState private var isKeyboardActive: Bool

  let onSend: () async throws -> Void

  var body: some View {
    @Bindable var model = model

    HStack(alignment: .center, spacing: 8) {
      // Input
      TextField(
        auth.isAuthenticated ? "Enter message" : "Log in to send a message",
        text: $model.text,
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
      .disabled(!auth.isAuthenticated)

      // Send
      Button {
        model.send(onSend)
      } label: {
        Image(systemName: "paperplane.fill")
          .font(.system(size: 22, weight: .semibold))
          .rotationEffect(.degrees(45))
      }
      .disabled(!model.canSend)
      .padding(.horizontal, 2)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .glassEffect()
    .padding(.horizontal, 16)
    .onDisappear { model.cancelSend() }
  }
}

#Preview {
  ChatInputBar {}
    .applyTheme()
    .environment(ThemeManager())
    .environment(AuthModel())
}
