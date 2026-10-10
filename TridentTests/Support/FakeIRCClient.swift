import DataModels
import Foundation
import TridentCore

/// An IRC client that records what it's asked to do and hands subscribers the events a test
/// pushes.
actor FakeIRCClient: IRCStreaming {
  private var continuation: AsyncStream<IRCStreamEvent>.Continuation?

  private(set) var subscriptions = 0
  private(set) var connectCount = 0
  private(set) var joined: [String] = []
  private(set) var parted: [String] = []

  /// When set, `join(to:)` throws it.
  var joinError: Error?

  func setJoinError(_ error: Error?) {
    joinError = error
  }

  func connect() async {
    connectCount += 1
  }

  func disconnect() async {}

  func join(to channel: Channel) async throws {
    if let joinError { throw joinError }
    joined.append(channel.loginName)
  }

  func part(from channel: Channel) async throws {
    parted.append(channel.loginName)
  }

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
