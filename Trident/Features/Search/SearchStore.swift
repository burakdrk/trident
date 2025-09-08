import AsyncAlgorithms

struct SearchState: StoreState {
  var searchText = ""
  var query = ""
}

struct SearchDependencies: StoreDependencies {
  let changes = AsyncChannel<String>()
}

typealias SearchStore = Store<SearchState, SearchDependencies>

extension SearchStore {
  func setSearchText(_ text: String) {
    update { $0.searchText = text }
    Task { await deps.changes.send(text) }
  }

  func startDebounceTask() async {
    for await value in deps.changes.debounce(for: .milliseconds(500)).removeDuplicates() {
      if Task.isCancelled { break }
      update { $0.query = value }
    }
  }
}
