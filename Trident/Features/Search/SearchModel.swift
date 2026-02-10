import AsyncAlgorithms

struct SearchState: Equatable {
  var searchText = ""
  var query = ""
}

struct SearchDependencies {
  let changes = AsyncChannel<String>()
}

typealias SearchModel = ViewModel<SearchState, NoIntent, SearchDependencies>

extension SearchModel {
  func startDebounceTask() async {
    for await value in dependencies.changes.debounce(for: .milliseconds(500)).removeDuplicates() {
      if Task.isCancelled { break }
      update { $0.query = value }
    }
  }
}
