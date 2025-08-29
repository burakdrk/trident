import AsyncAlgorithms
import Foundation
import Observation

@Observable
final class SearchStore: DataStore {
  struct State: Equatable {
    var query: String = ""
  }

  enum Action {
    case setQuery(String?)
    case _setDebouncedQuery(String)
  }

  private(set) var state = State()
  @ObservationIgnored private let changes = AsyncChannel<String>()
  @ObservationIgnored private var debounceTask: Task<Void, Never>?

  init() { startDebounceLoop() }
  deinit { changes.finish(); debounceTask?.cancel() }

  func dispatch(_ action: Action) {
    switch action {
    case let .setQuery(query):
      Task { @MainActor in
        await changes.send(query ?? "")
      }
    case let ._setDebouncedQuery(query):
      state.query = query
    }
  }

  private func startDebounceLoop() {
    debounceTask?.cancel()
    debounceTask = Task { [weak self, changes] in
      for await value in changes.debounce(for: .milliseconds(500)).removeDuplicates() {
        self?.dispatch(._setDebouncedQuery(value))
      }
    }
  }
}
