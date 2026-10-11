import DataModels
import Dependencies
import Foundation
import Testing
@testable import Trident
import TridentCore

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct StreamManagerTests {
  private let clock = TestClock<Duration>()
  private let irc = FakeIRCClient()
  private let now = LockIsolated(Date(timeIntervalSince1970: 1_000_000))

  private let forsen = Channel.mockList[0]
  private let xqc = Channel.mockList[1]

  private func makeModel(idleTimeout: TimeInterval = 60) -> StreamManagerModel {
    withDependencies {
      $0.continuousClock = clock
      $0.ircClient = irc
      $0.assetClient = AssetClient { _ in [:] }
      $0.date = DateGenerator { [now] in now.value }
    } operation: {
      StreamManagerModel(idleTimeout: idleTimeout)
    }
  }

  private struct JoinFailed: LocalizedError {
    var errorDescription: String? { "nope" }
  }

  /// Runs the cleanup loop and returns after `condition` holds, stepping the fake clock.
  private func runCleanup(
    _ model: StreamManagerModel,
    until condition: () -> Bool
  ) async {
    let task = Task { await model.startIdleStreamCleanup() }
    defer { task.cancel() }

    for _ in 0..<500 {
      if condition() { return }
      await clock.advance(by: .seconds(10))
      try? await Task.sleep(for: .milliseconds(3))
    }
    Issue.record("Timed out waiting for the idle cleanup")
  }

  // MARK: - Loading

  @Test func loadingAChannelConnectsJoinsAndCreatesItsChat() async {
    let model = makeModel()

    await model.loadStream(for: forsen)

    #expect(model.activeChannels[forsen]?.channel == forsen)
    #expect(await irc.connectCount == 1)
    #expect(await irc.joined == ["forsen"])
  }

  @Test func loadingTheSameChannelTwiceCreatesOneChat() async {
    let model = makeModel()

    async let first: Void = model.loadStream(for: forsen)
    async let second: Void = model.loadStream(for: forsen)
    _ = await (first, second)
    let chat = model.activeChannels[forsen]

    await model.loadStream(for: forsen)

    #expect(model.activeChannels.count == 1)
    #expect(model.activeChannels[forsen] === chat)
    #expect(await irc.joined == ["forsen"])
  }

  @Test func aFailedJoinIsRecordedAndNoChatIsCreated() async {
    let model = makeModel()
    await irc.setJoinError(JoinFailed())

    await model.loadStream(for: forsen)

    #expect(model.activeChannels[forsen] == nil)
    #expect(model.loadFailures[forsen] == "nope")
  }

  @Test func retryingAfterAFailureClearsIt() async {
    let model = makeModel()
    await irc.setJoinError(JoinFailed())
    await model.loadStream(for: forsen)

    await irc.setJoinError(nil)
    await model.loadStream(for: forsen)

    #expect(model.activeChannels[forsen] != nil)
    #expect(model.loadFailures[forsen] == nil)
  }

  // MARK: - Idle cleanup

  @Test func unloadsAChannelOnceItHasBeenOutOfViewLongEnough() async {
    let model = makeModel(idleTimeout: 60)
    model.visibleChannel = forsen
    await model.loadStream(for: forsen)
    model.visibleChannel = xqc
    await model.loadStream(for: xqc)

    now.withValue { $0.addTimeInterval(61) }
    await runCleanup(model) { model.activeChannels[forsen] == nil }

    #expect(model.activeChannels[forsen] == nil)
    #expect(await irc.parted == ["forsen"])
  }

  @Test func keepsTheVisibleChannelNoMatterHowLongItHasBeenThere() async {
    let model = makeModel(idleTimeout: 60)
    model.visibleChannel = forsen
    await model.loadStream(for: forsen)

    now.withValue { $0.addTimeInterval(3_600) }
    let task = Task { await model.startIdleStreamCleanup() }
    defer { task.cancel() }
    for _ in 0..<4 {
      await clock.advance(by: .seconds(10))
      try? await Task.sleep(for: .milliseconds(3))
    }

    #expect(model.activeChannels[forsen] != nil)
    #expect(await irc.parted.isEmpty)
  }

  @Test func keepsAChannelThatWasOutOfViewForLessThanTheTimeout() async {
    let model = makeModel(idleTimeout: 60)
    model.visibleChannel = forsen
    await model.loadStream(for: forsen)
    model.visibleChannel = xqc
    await model.loadStream(for: xqc)

    now.withValue { $0.addTimeInterval(30) }
    let task = Task { await model.startIdleStreamCleanup() }
    defer { task.cancel() }
    for _ in 0..<4 {
      await clock.advance(by: .seconds(10))
      try? await Task.sleep(for: .milliseconds(3))
    }

    #expect(model.activeChannels[forsen] != nil)
  }

  @Test func comingBackResetsTheIdleTimer() async {
    let model = makeModel(idleTimeout: 60)
    model.visibleChannel = forsen
    await model.loadStream(for: forsen)
    model.visibleChannel = xqc
    await model.loadStream(for: xqc)

    now.withValue { $0.addTimeInterval(50) }
    model.visibleChannel = forsen // back, then away again
    model.visibleChannel = xqc
    now.withValue { $0.addTimeInterval(50) } // 100s since first leaving, 50s since the last

    let task = Task { await model.startIdleStreamCleanup() }
    defer { task.cancel() }
    for _ in 0..<4 {
      await clock.advance(by: .seconds(10))
      try? await Task.sleep(for: .milliseconds(3))
    }

    #expect(model.activeChannels[forsen] != nil)
  }

  @Test func theDefaultTimeoutIsFiveMinutes() {
    // Guards against a debugging value sneaking back in.
    #expect(StreamManagerModel.defaultIdleTimeout == 300)
  }
}
