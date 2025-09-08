import SwiftUI

struct ChatInputState: StoreState {
  var text = ""
  var isSending = false
}

struct ChatInputDependencies: StoreDependencies {}

typealias ChatInputStore = Store<ChatInputState, ChatInputDependencies>

extension ChatInputStore {
  func reset() {
    update { $0.text = "" }
  }

  func setText(_ text: String) {
    update { $0.text = text }
  }

  func sendIfNeeded(_ action: @Sendable () async throws -> Void) {
    guard
      !state.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      !state.isSending else { return }

    Task {
      update { $0.isSending = true }
      defer { update { $0.isSending = false } }
      try await Task.sleep(nanoseconds: 500_000_000)
      reset()
    }
  }
}
