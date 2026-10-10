import Dependencies
import Foundation
import Testing
@testable import Trident

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct SearchModelTests {
  private let clock = TestClock<Duration>()

  private func makeModel() -> SearchModel {
    withDependencies {
      $0.continuousClock = clock
    } operation: {
      SearchModel()
    }
  }

  /// Gives the model's task a moment to reach its sleep, then moves the fake clock.
  private func pass(_ duration: Duration) async {
    try? await Task.sleep(for: .milliseconds(30))
    await clock.advance(by: duration)
    try? await Task.sleep(for: .milliseconds(30))
  }

  @Test func queryFollowsTheTextOnceTypingPauses() async {
    let model = makeModel()
    model.searchText = "forsen"

    let task = Task { await model.updateQuery() }
    await pass(.milliseconds(500))
    await task.value

    #expect(model.query == "forsen")
  }

  @Test func queryStaysPutWhileTheUserIsStillTyping() async {
    let model = makeModel()
    model.searchText = "for"

    let task = Task { await model.updateQuery() }
    await pass(.milliseconds(499))

    #expect(model.query.isEmpty)

    await pass(.milliseconds(1))
    await task.value
    #expect(model.query == "for")
  }

  /// `.task(id: searchText)` cancels the previous run for every keystroke. Only the last survives.
  @Test func aKeystrokeCancelsThePendingUpdate() async {
    let model = makeModel()

    model.searchText = "f"
    let first = Task { await model.updateQuery() }
    try? await Task.sleep(for: .milliseconds(30))
    await clock.advance(by: .milliseconds(300))

    first.cancel()
    model.searchText = "fo"
    let second = Task { await model.updateQuery() }
    await pass(.milliseconds(300)) // 600ms after the first keystroke, 300ms after the second

    #expect(model.query.isEmpty)

    await pass(.milliseconds(200))
    await second.value
    await first.value
    #expect(model.query == "fo")
  }
}
