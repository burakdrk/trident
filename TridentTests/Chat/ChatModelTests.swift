import DataModels
import Dependencies
import Foundation
import Testing
@testable import Trident
import TridentCore
import TwitchIRC

/// An IRC client that does nothing but hand the model the events a test pushes.
private actor FakeIRCClient: IRCStreaming {
  private var continuation: AsyncStream<IRCStreamEvent>.Continuation?
  private(set) var subscriptions = 0

  func connect() async {}
  func disconnect() async {}
  func join(to channel: Channel) async throws {}
  func part(from channel: Channel) async throws {}

  func subscribe(to channel: Channel?) -> AsyncStream<IRCStreamEvent> {
    subscriptions += 1
    let (stream, continuation) = AsyncStream.makeStream(of: IRCStreamEvent.self)
    self.continuation = continuation
    return stream
  }

  func emit(_ event: IRCStreamEvent) {
    continuation?.yield(event)
  }
}

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct ChatModelTests {
  private let clock = TestClock<Duration>()
  private let irc = FakeIRCClient()
  private let recents = LockIsolated<[ChatMessage]>([])

  private func makeModel() -> ChatModel {
    withDependencies {
      $0.continuousClock = clock
      $0.ircClient = irc
      $0.recentMessages = RecentMessagesClient { [recents] _, _ in recents.value }
    } operation: {
      ChatModel(for: .mock)
    }
  }

  private nonisolated func recent(_ id: String) -> ChatMessage {
    ChatMessage(
      id: id,
      inlines: [.text(id)],
      author: .init(displayName: "a", colorHex: "#FFFFFF", badges: []),
      timestamp: .now,
      rawText: id,
      historical: true
    )
  }

  private func live(_ id: String) throws -> IRCStreamEvent {
    let raw = "@badge-info=;badges=;color=#0D4200;display-name=ronni;emotes=;id=\(id);mod=0;"
      + "room-id=1337;subscriber=0;tmi-sent-ts=1507246572675;turbo=0;user-id=1337;user-type= "
      + ":ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #forsen :\(id)"

    guard let message = IncomingMessage.parse(ircOutput: raw).first?.message else {
      throw ParseFailure()
    }
    return .message(message)
  }

  private struct ParseFailure: Error {}

  /// Runs the model like the chat view does, until the returned tasks are cancelled.
  private func run(_ model: ChatModel) -> [Task<Void, Never>] {
    [
      Task { await model.startReading() },
      Task { await model.startRendering() }
    ]
  }

  private func waitForSubscriptions(_ count: Int) async {
    for _ in 0..<1_000 {
      if await irc.subscriptions >= count { return }
      try? await Task.sleep(for: .milliseconds(5))
    }
    Issue.record("Model never subscribed")
  }

  /// Steps the fake clock so the render loop flushes, until `condition` holds.
  private func render(until condition: () -> Bool) async {
    for _ in 0..<1_000 {
      if condition() { return }
      await clock.advance(by: .milliseconds(150))
      try? await Task.sleep(for: .milliseconds(5))
    }
    Issue.record("Timed out waiting for the chat to render")
  }

  /// Lets the model process everything it was sent, for tests that check something did *not*
  /// happen.
  private func settle() async {
    for _ in 0..<5 {
      await clock.advance(by: .milliseconds(150))
      try? await Task.sleep(for: .milliseconds(10))
    }
  }

  // MARK: - Messages

  @Test func showsRecentsBeforeLiveMessagesNewestAtTheBottom() async throws {
    recents.setValue([recent("r1"), recent("r2")])
    let model = makeModel()
    let tasks = run(model)
    defer { tasks.forEach { $0.cancel() } }

    await waitForSubscriptions(1)
    try await irc.emit(live("l1"))
    await render { model.messages.count == 3 }

    // Index 0 is the newest, which the flipped table shows at the bottom.
    #expect(model.messages.map(\.id) == ["l1", "r2", "r1"])
  }

  @Test func showsAMessageOnlyOnceWhenItIsBothLiveAndRecent() async throws {
    recents.setValue([recent("same")])
    let model = makeModel()
    let tasks = run(model)
    defer { tasks.forEach { $0.cancel() } }

    await waitForSubscriptions(1)
    try await irc.emit(live("same"))
    try await irc.emit(live("other"))
    await render { model.messages.count == 2 }
    await settle()

    #expect(model.messages.map(\.id) == ["other", "same"])
  }

  @Test func fillsTheGapWithoutDuplicatesWhenReadingResumes() async {
    recents.setValue([recent("a")])
    let model = makeModel()

    var tasks = run(model)
    await waitForSubscriptions(1)
    await render { model.messages.count == 1 }
    tasks.forEach { $0.cancel() }

    // While we weren't reading, "b" arrived. Recents now knows about it.
    recents.setValue([recent("a"), recent("b")])
    tasks = run(model)
    defer { tasks.forEach { $0.cancel() } }

    await waitForSubscriptions(2)
    await render { model.messages.count == 2 }

    #expect(model.messages.map(\.id) == ["b", "a"])
  }

  // MARK: - Connection

  @Test func startsOutConnecting() {
    #expect(makeModel().connection == .connecting)
  }

  @Test func isLiveOnceAuthenticated() async {
    let model = makeModel()
    let tasks = run(model)
    defer { tasks.forEach { $0.cancel() } }

    await waitForSubscriptions(1)
    await irc.emit(.status(.connecting))
    await irc.emit(.status(.authenticated))

    await render { model.connection == .live }
    #expect(model.connection == .live)
  }

  @Test func neverGoesBackToConnectingAfterBeingLive() async {
    let model = makeModel()
    let tasks = run(model)
    defer { tasks.forEach { $0.cancel() } }

    await waitForSubscriptions(1)
    await irc.emit(.status(.authenticated))
    await render { model.connection == .live }

    await irc.emit(.status(.failed(URLError(.networkConnectionLost))))
    await render { model.connection == .reconnecting }
    await irc.emit(.status(.connecting))
    await irc.emit(.status(.connected))
    await settle()

    #expect(model.connection == .reconnecting)

    await irc.emit(.status(.authenticated))
    await render { model.connection == .live }
    #expect(model.connection == .live)
  }

  @Test func failingBeforeEverBeingLiveStillSaysConnecting() async {
    let model = makeModel()
    let tasks = run(model)
    defer { tasks.forEach { $0.cancel() } }

    await waitForSubscriptions(1)
    await irc.emit(.status(.failed(URLError(.notConnectedToInternet))))
    await settle()

    #expect(model.connection == .connecting)
  }
}
