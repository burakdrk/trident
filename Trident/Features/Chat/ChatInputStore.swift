import SwiftUI

@Observable
final class ChatInputStore: DataStore {
  struct State: Equatable {
    var text = ""
    var isSending = false
  }

  enum Action {
    case reset
    case sendIfNeeded(@Sendable () async throws -> Void)
  }

  var state = State()

  func dispatch(_ action: Action) {
    switch action {
    case .reset:
      state.text = ""

    case .sendIfNeeded(let action):
      sendIfNeeded(action)
    }
  }

  /// Do your send here (network, DB, etc.)
  private func sendIfNeeded(_ action: @MainActor () async throws -> Void) {
    guard
      !state.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      !state.isSending else { return }

    state.isSending = true

    Task { @MainActor in
      defer { state.isSending = false }
      try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
      await MainActor.run { self.dispatch(.reset) }
    }
  }
}
