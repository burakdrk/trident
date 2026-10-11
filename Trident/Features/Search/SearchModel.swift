import Dependencies
import SwiftUI

private enum Constants {
  static let debounce: Duration = .milliseconds(500)
}

@Observable
final class SearchModel {
  /// What the user is typing.
  var searchText = ""

  /// `searchText`, once the user has stopped typing for a moment.
  private(set) var query = ""

  @ObservationIgnored @Dependency(\.continuousClock) private var clock

  /// Run with `.task(id: searchText)`. SwiftUI cancels the previous run whenever the text changes,
  /// so only the last keystroke survives the sleep.
  func updateQuery() async {
    try? await clock.sleep(for: Constants.debounce)
    guard !Task.isCancelled, query != searchText else { return }
    query = searchText
  }
}
