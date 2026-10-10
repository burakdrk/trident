import DataModels
import Dependencies
import Foundation
import TwitchIRC
import Utilities

private enum Constants {
  static let defaultUsername = "justinfan28264"
  static let defaultPassword = "SCHMOOPIIE"
  static let handshakeTimeout: Duration = .seconds(10)
  static let maxBackoffSeconds = 30
}

public enum IRCStreamEvent: Sendable {
  public enum ConnectionStatus: Sendable {
    /// Disconnected from the socket
    case disconnected

    /// Connecting to the socket
    case connecting

    /// Socket open, but not logged in to Twitch
    case connected

    /// Logged in successfully
    case authenticated

    /// The connection failed or dropped. The client keeps trying to reconnect unless
    /// `disconnect()` was called.
    case failed(Error)
  }

  case message(IncomingMessage)
  case status(ConnectionStatus)
}

public protocol IRCStreaming: Sendable {
  /// Starts connecting and keeps the connection alive, reconnecting with backoff when it drops,
  /// until `disconnect()` is called.
  func connect() async
  func disconnect() async

  /// Returns a new stream for a specific client. The current connection status is delivered first.
  /// - Parameter channel: If provided, only messages for this channel will be yielded.
  /// - Returns: An `AsyncStream` of `IRCStreamEvent`s.
  func subscribe(to channel: Channel?) async -> AsyncStream<IRCStreamEvent>

  /// Marks the channel as wanted. It's joined right away when connected, and rejoined after every
  /// reconnect, so it's fine to call before `connect()` finishes.
  func join(to channel: Channel) async throws

  /// The opposite of `join(to:)`.
  func part(from channel: Channel) async throws
}

actor IRCClient: IRCStreaming {
  @Dependency(\.uuid) private var uuidGenerator
  @Dependency(\.continuousClock) private var clock
  @Dependency(\.ircSocketFactory) private var socketFactory

  private var socket: (any IRCSocket)?
  private var receiveTask: Task<Void, Never>?
  private var reconnectTask: Task<Void, Never>?
  private var reconnectID: UUID?

  private var subscribers: [
    UUID: (channel: Channel?, continuation: AsyncStream<IRCStreamEvent>.Continuation)
  ] = [:]

  /// Channels the app wants to be in, independent of the state of the connection.
  private var desiredChannels: Set<String> = []

  /// True between `connect()` and `disconnect()`. Decides whether a dropped connection is retried.
  private var wantsConnection = false
  private var currentStatus: IRCStreamEvent.ConnectionStatus = .disconnected

  private var isConnected: Bool {
    switch currentStatus {
    case .connected, .authenticated: socket != nil
    default: false
    }
  }

  private var isAuthenticated: Bool {
    if case .authenticated = currentStatus { true } else { false }
  }

  // MARK: - Connection

  func connect() async {
    wantsConnection = true

    // A reconnect loop is already working on it.
    guard reconnectTask == nil else { return }

    switch currentStatus {
    case .disconnected, .failed: break
    default: return
    }

    if await !openConnection() {
      startReconnecting()
    }
  }

  func disconnect() {
    TridentLog.main.info("Closing IRC connection")

    wantsConnection = false
    reconnectTask?.cancel()
    reconnectTask = nil
    reconnectID = nil
    receiveTask?.cancel()
    receiveTask = nil
    socket?.close()
    socket = nil

    broadcastStatus(.disconnected)

    // We do NOT finish the subscriber streams here.
    // We keep them open so the UI doesn't break, allowing for reconnection.
  }

  /// Opens a socket and logs in. Returns false if that failed or `disconnect()` got in the way.
  private func openConnection() async -> Bool {
    broadcastStatus(.connecting)

    let socket = socketFactory.make()
    self.socket = socket

    do {
      try await withHandshakeTimeout(closing: socket) {
        try await Self.handshake(on: socket)
      }
    } catch {
      // `disconnect()` already took care of everything.
      guard self.socket === socket else { return false }

      TridentLog.main.error("IRC handshake failed: \(error.localizedDescription)")
      socket.close()
      self.socket = nil
      broadcastStatus(.failed(error))
      return false
    }

    guard self.socket === socket else { return false }

    broadcastStatus(.connected)
    startReceiving(on: socket)

    for channel in desiredChannels.sorted() {
      try? await send(.join(to: channel))
    }

    return true
  }

  private func startReceiving(on socket: any IRCSocket) {
    receiveTask?.cancel()

    receiveTask = Task { [weak self] in
      do {
        while !Task.isCancelled {
          let text = try await socket.receive()
          guard let self else { return }
          await handle(text, from: socket)
        }
      } catch {
        await self?.connectionLost(error, on: socket)
      }
    }
  }

  private func connectionLost(_ error: Error, on socket: any IRCSocket) {
    // Ignore leftovers from a socket we already replaced or closed on purpose.
    guard self.socket === socket else { return }

    TridentLog.main.error("IRC connection lost: \(error.localizedDescription)")

    socket.close()
    self.socket = nil
    receiveTask?.cancel()
    receiveTask = nil

    broadcastStatus(.failed(error))
    startReconnecting()
  }

  // MARK: - Reconnecting

  static func backoff(forAttempt attempt: Int) -> Duration {
    .seconds(min(Constants.maxBackoffSeconds, 1 << min(attempt, 5)))
  }

  private func startReconnecting() {
    guard wantsConnection, reconnectTask == nil else { return }

    let id = uuidGenerator()
    reconnectID = id
    reconnectTask = Task { await self.reconnect(id: id) }
  }

  private func reconnect(id: UUID) async {
    // `disconnect()` + `connect()` may have started a newer loop while this one was winding down.
    defer {
      if reconnectID == id {
        reconnectID = nil
        reconnectTask = nil
      }
    }

    var attempt = 0

    while wantsConnection {
      do {
        try await clock.sleep(for: Self.backoff(forAttempt: attempt))
      } catch {
        return
      }

      guard wantsConnection, reconnectID == id else { return }
      if await openConnection() { return }

      attempt += 1
    }
  }

  // MARK: - Subscriptions

  func subscribe(to channel: Channel? = nil) -> AsyncStream<IRCStreamEvent> {
    let id = uuidGenerator()

    return AsyncStream { continuation in
      self.addSubscriber(id: id, channel: channel, continuation: continuation)

      // Auto-cleanup when the client stops iterating or the Task is cancelled
      continuation.onTermination = { [weak self] _ in
        Task { [weak self] in
          await self?.removeSubscriber(id: id)
        }
      }
    }
  }

  private func addSubscriber(
    id: UUID,
    channel: Channel?,
    continuation: AsyncStream<IRCStreamEvent>.Continuation
  ) {
    subscribers[id] = (channel, continuation)
    continuation.yield(.status(currentStatus))
  }

  private func removeSubscriber(id: UUID) {
    subscribers.removeValue(forKey: id)
  }

  // MARK: - Channels

  func join(to channel: Channel) async throws {
    guard desiredChannels.insert(channel.loginName).inserted else { return }
    guard isConnected else { return } // Joined once the connection is up.

    do {
      try await send(.join(to: channel.loginName))
    } catch {
      desiredChannels.remove(channel.loginName)
      throw error
    }
  }

  func part(from channel: Channel) async throws {
    guard desiredChannels.remove(channel.loginName) != nil else { return }
    guard isConnected else { return }

    // If this fails the connection is going down, and a new one won't rejoin the channel anyway.
    try? await send(.part(from: channel.loginName))
  }

  // MARK: - Incoming

  private func handle(_ text: String, from socket: any IRCSocket) async {
    guard self.socket === socket else { return }

    for msg in IncomingMessage.parse(ircOutput: text).compactMap(\.message) {
      switch msg {
      case .ping:
        try? await send(.pong)
      case let .connectionNotice(notice):
        guard !isAuthenticated else { break }
        broadcastStatus(.authenticated)

        TridentLog.main
          .info("Logged into IRC with \(notice.userLogin), message from Twitch: \(notice.message)")
      case .reconnect:
        connectionLost(IRCError.serverRequestedReconnect, on: socket)
        return
      default: break
      }

      route(msg)
    }
  }

  /// If a channel filter is provided, return chat messages only meant for that channel
  /// (This will still return all non-chat messages)
  private func route(_ msg: IncomingMessage) {
    for (_, (filterChannel, continuation)) in subscribers {
      if let filterChannel {
        switch msg {
        case let .privateMessage(chatMsg):
          if chatMsg.channel == filterChannel.loginName {
            continuation.yield(.message(msg))
          }
        default:
          continuation.yield(.message(msg))
        }
      } else {
        continuation.yield(.message(msg))
      }
    }
  }
}

// MARK: - Helpers

private extension IRCClient {
  func send(_ twitchMessage: OutgoingMessage) async throws {
    guard let socket, isConnected else { throw IRCError.notConnected }
    try await socket.send(twitchMessage.serialize())
  }

  /// Broadcasts status messages to all subscribers
  func broadcastStatus(_ status: IRCStreamEvent.ConnectionStatus) {
    currentStatus = status
    for (_, (_, continuation)) in subscribers {
      continuation.yield(.status(status))
    }
  }

  /// Races `work` against the handshake timeout. The socket is closed when the timeout wins, which
  /// is what unblocks a `receive()` that would otherwise keep the work from ever finishing.
  func withHandshakeTimeout(
    closing socket: any IRCSocket,
    _ work: @Sendable @escaping () async throws -> Void
  ) async throws {
    let clock = clock

    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask { try await work() }
      group.addTask {
        try await clock.sleep(for: Constants.handshakeTimeout)
        socket.close()
        throw IRCError.timedOut
      }

      defer { group.cancelAll() }
      try await group.next()
    }
  }

  static func handshake(on socket: any IRCSocket) async throws {
    try await socket.send(OutgoingMessage.capabilities([.tags, .commands]).serialize())

    let acknowledged = try await IncomingMessage.parse(ircOutput: socket.receive())
      .compactMap(\.message)
      .contains {
        if case .capabilities = $0 { true } else { false }
      }

    guard acknowledged else { throw IRCError.failedToConnect }

    try await socket.send(OutgoingMessage.pass(pass: Constants.defaultPassword).serialize())
    try await socket.send(OutgoingMessage.nick(name: Constants.defaultUsername).serialize())
  }
}

// MARK: - Dependency Registration

private enum IRCClientKey: DependencyKey {
  static let liveValue: any IRCStreaming = IRCClient()
}

public extension DependencyValues {
  var ircClient: any IRCStreaming {
    get { self[IRCClientKey.self] }
    set { self[IRCClientKey.self] = newValue }
  }
}
