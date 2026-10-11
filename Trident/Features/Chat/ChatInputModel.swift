import SwiftUI

@Observable
final class ChatInputModel {
  var text = ""
  private(set) var isSending = false

  var canSend: Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
  }

  @ObservationIgnored private var sendTask: Task<Void, Never>?

  /// Runs `action` and clears the text when it succeeds. The text is kept on failure so the user
  /// can retry.
  func send(_ action: @escaping () async throws -> Void) {
    guard canSend else { return }
    isSending = true

    sendTask = Task {
      defer { isSending = false }

      do {
        try await action()
        text = ""
      } catch {}
    }
  }

  func cancelSend() {
    sendTask?.cancel()
    sendTask = nil
  }
}
