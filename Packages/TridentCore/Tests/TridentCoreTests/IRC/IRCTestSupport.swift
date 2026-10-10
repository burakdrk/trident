import DataModels
import Dependencies
import Foundation
import Testing
@testable import TridentCore
import TwitchIRC

// MARK: - Fake socket

/// A scripted stand-in for the Twitch websocket.
final class FakeSocket: IRCSocket {
  static let capabilitiesAck =
    ":tmi.twitch.tv CAP * ACK :twitch.tv/tags twitch.tv/commands\r\n"
  static let welcome = ":tmi.twitch.tv 001 justinfan28264 :Welcome, GLHF!\r\n"
  static let ping = "PING :tmi.twitch.tv\r\n"
  static let reconnect = ":tmi.twitch.tv RECONNECT\r\n"

  /// Everything the client sent, in order.
  let sent = LockIsolated<[String]>([])
  let isClosed = LockIsolated(false)

  private let failsOnSend: Bool
  private let inbox: Inbox
  private let continuation: AsyncThrowingStream<String, Error>.Continuation

  /// - Parameters:
  ///   - acknowledgesCapabilities: Queue the reply the handshake waits for.
  ///   - failsOnSend: Make every send throw, so the handshake fails.
  init(acknowledgesCapabilities: Bool = true, failsOnSend: Bool = false) {
    let (stream, continuation) = AsyncThrowingStream<String, Error>.makeStream()
    inbox = Inbox(stream)
    self.continuation = continuation
    self.failsOnSend = failsOnSend

    if acknowledgesCapabilities { continuation.yield(Self.capabilitiesAck) }
  }

  func send(_ text: String) async throws {
    if failsOnSend || isClosed.value { throw URLError(.networkConnectionLost) }
    sent.withValue { $0.append(text) }
  }

  func receive() async throws -> String {
    guard let text = try await inbox.next() else { throw URLError(.networkConnectionLost) }
    return text
  }

  func close() {
    isClosed.setValue(true)
    continuation.finish(throwing: URLError(.cancelled))
  }

  /// Delivers a frame from "Twitch".
  func push(_ text: String) {
    continuation.yield(text)
  }

  /// Simulates the connection dying under the client.
  func drop() {
    continuation.finish(throwing: URLError(.networkConnectionLost))
  }

  /// Only one `receive()` is ever pending on a socket, so the iterator needs no locking.
  private final class Inbox: @unchecked Sendable {
    private var iterator: AsyncThrowingStream<String, Error>.Iterator

    init(_ stream: AsyncThrowingStream<String, Error>) {
      iterator = stream.makeAsyncIterator()
    }

    func next() async throws -> String? {
      try await iterator.next()
    }
  }
}

// MARK: - Harness

/// Builds clients wired to fake sockets and a clock the test controls.
final class IRCHarness: Sendable {
  let clock = TestClock<Duration>()
  let sockets = LockIsolated<[FakeSocket]>([])

  /// Decides what the n-th socket (0-based) the client opens looks like.
  let socketForAttempt = LockIsolated<@Sendable (Int) -> FakeSocket>({ _ in FakeSocket() })

  func makeClient() -> IRCClient {
    withDependencies {
      $0.continuousClock = clock
      $0.uuid = .incrementing
      $0.ircSocketFactory = IRCSocketFactory { [self] in
        let socket = socketForAttempt.value(sockets.count)
        sockets.withValue { $0.append(socket) }
        return socket
      }
    } operation: {
      IRCClient()
    }
  }

  /// Advances the fake clock in small steps until `condition` holds and returns how far it had to
  /// go. Stepping (instead of one big jump) lets tests check backoff durations, and it doesn't
  /// matter if the client hasn't started sleeping yet.
  @discardableResult
  func advance(
    by step: Duration = .milliseconds(100),
    until condition: @Sendable () -> Bool,
    limit: Duration = .seconds(120)
  ) async -> Duration {
    var total = Duration.zero

    while !condition(), total < limit {
      await clock.advance(by: step)
      total += step
      try? await Task.sleep(for: .milliseconds(2))
    }

    return total
  }

  /// Advances the fake clock without waiting for anything.
  func advance(by duration: Duration) async {
    await clock.advance(by: duration)
    try? await Task.sleep(for: .milliseconds(20))
  }
}

// MARK: - Recording events

enum RecordedStatus: Equatable {
  case disconnected, connecting, connected, authenticated, failed(String?)
}

/// Collects everything a client subscription yields.
final class EventRecorder: Sendable {
  private let events = LockIsolated<[IRCStreamEvent]>([])
  private let task: Task<Void, Never>

  init(_ stream: AsyncStream<IRCStreamEvent>) {
    let events = events
    task = Task {
      for await event in stream {
        events.withValue { $0.append(event) }
      }
    }
  }

  deinit { task.cancel() }

  var statuses: [RecordedStatus] {
    events.value.compactMap { event in
      guard case let .status(status) = event else { return nil }
      switch status {
      case .disconnected: return .disconnected
      case .connecting: return .connecting
      case .connected: return .connected
      case .authenticated: return .authenticated
      case let .failed(error): return .failed(error.localizedDescription)
      }
    }
  }

  var messages: [IncomingMessage] {
    events.value.compactMap { event in
      guard case let .message(message) = event else { return nil }
      return message
    }
  }
}

// MARK: - Waiting

/// Polls in real time until `condition` holds. Fails the test on timeout.
func waitUntil(
  _ description: String,
  timeout: Duration = .seconds(5),
  sourceLocation: SourceLocation = #_sourceLocation,
  _ condition: @Sendable () -> Bool
) async {
  let deadline = ContinuousClock.now + timeout

  while !condition() {
    if ContinuousClock.now > deadline {
      Issue.record("Timed out waiting for \(description)", sourceLocation: sourceLocation)
      return
    }
    try? await Task.sleep(for: .milliseconds(5))
  }
}

// MARK: - Sample data

extension Channel {
  static func sample(_ login: String) -> Channel {
    Channel(
      id: login,
      loginName: login,
      displayName: login,
      avatarURL: URL(string: "https://example.com/\(login).png")! // swiftlint:disable:this force_unwrapping
    )
  }
}

func privateMessage(in channel: String, text: String = "hello") -> String {
  "@badge-info=;badges=;color=#0D4200;display-name=ronni;emotes=;id=\(UUID().uuidString);mod=0;"
    + "room-id=1337;subscriber=0;tmi-sent-ts=1507246572675;turbo=0;user-id=1337;user-type= "
    + ":ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #\(channel) :\(text)\r\n"
}
