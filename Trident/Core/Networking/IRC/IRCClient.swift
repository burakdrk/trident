import Dependencies
import Foundation
import TwitchIRC

private enum Constants {
  static let wsUrl = "wss://irc-ws.chat.twitch.tv:443"
  static let defaultUsername = "justinfan28264"
  static let defaultPassword = "SCHMOOPIIE"
}

enum IRCStreamEvent {
  enum ConnectionStatus {
    /// Disconnected from the socket
    case disconnected

    /// Connecting to the socket
    case connecting

    /// Socket open, but not logged in to Twitch
    case connected

    /// Logged in successfully
    case authenticated

    case failed(Error)
  }

  case message(IncomingMessage)
  case status(ConnectionStatus)
}

protocol IRCStreaming: Sendable {
  func connect() async
  func disconnect() async

  /// Returns a new stream for a specific client.
  /// - Parameter channel: If provided, only messages for this channel will be yielded.
  /// - Returns: An `AsyncStream` of `IRCStreamEvent`s.
  func subscribe(to channel: Channel?) async -> AsyncStream<IRCStreamEvent>

  func join(to channel: Channel) async throws
  func part(from channel: Channel) async throws
}

actor IRCClient: IRCStreaming {
  @Dependency(\.uuid) private var uuidGenerator
  @Dependency(\.urlSession) private var urlSession

  private var websocket: URLSessionWebSocketTask?
  private var subscribers: [
    UUID: (channel: Channel?, continuation: AsyncStream<IRCStreamEvent>.Continuation)
  ] = [:]
  private var joinedChannels: Set<String> = []
  private var currentStatus: IRCStreamEvent.ConnectionStatus = .disconnected

  // MARK: - WebSocket Connection

  func connect() async {
    switch currentStatus {
    case .disconnected, .failed: break
    default: return
    }

    broadcastStatus(.connecting)

    websocket = urlSession.webSocketTask(with: URL.make(Constants.wsUrl))
    websocket?.resume()

    do {
      try await requestCapabilities()
      try await authenticate()
    } catch {
      broadcastStatus(.failed(error))
      return
    }

    startReceiving()
    broadcastStatus(.connected)
  }

  func disconnect() {
    TridentLog.main.info("Closing IRC connection")
    websocket?.cancel(with: .goingAway, reason: nil)
    websocket = nil
    broadcastStatus(.disconnected)

    // We do NOT finish the subscriber streams here.
    // We keep them open so the UI doesn't break, allowing for reconnection.
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
  }

  private func removeSubscriber(id: UUID) {
    subscribers.removeValue(forKey: id)
  }

  // MARK: - Twitch Broadcast Logic

  private func startReceiving() {
    Task { [weak self] in
      var isAlive = true

      while isAlive {
        guard let self else { break }

        do {
          let messages = try await receiveMsg()

          // Broadcast to all valid subscribers
          for msg in messages {
            await broadcast(msg)
          }
        } catch {
          TridentLog.main.error("Socket error: \(error)")
          isAlive = false
          await broadcastStatus(.failed(error))
        }
      }
    }
  }

  private func broadcast(_ msg: IncomingMessage) {
    // Handle internal logic for stuff like pings, joins etc.
    switch msg {
    case .ping:
      Task { try? await sendMsg(.pong) }
    case let .join(join):
      joinedChannels.insert(join.channel)
    case let .part(part):
      joinedChannels.remove(part.channel)
    case let .connectionNotice(notice):
      broadcastStatus(.authenticated)

      TridentLog.main
        .info("Logged into IRC with \(notice.userLogin), message from Twitch: \(notice.message)")
    default: break
    }

    // If a channel filter is provided, return chat messages only meant for that channel
    // (This will still return all non-chat messages)
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

  func join(to channel: Channel) async throws {
    guard !joinedChannels.contains(channel.loginName) else { return }
    try await sendMsg(.join(to: channel.loginName))
  }

  func part(from channel: Channel) async throws {
    guard joinedChannels.contains(channel.loginName) else { return }
    try await sendMsg(.part(from: channel.loginName))
  }
}

// MARK: - Helpers

private extension IRCClient {
  func sendMsg(_ twitchMessage: OutgoingMessage) async throws {
    guard let websocket else { return }
    try await websocket.send(.string(twitchMessage.serialize()))
  }

  func receiveMsg() async throws -> [IncomingMessage] {
    guard let websocket else { return [] }

    let result = try await websocket.receive()
    if case let .string(msgStr) = result {
      return IncomingMessage.parse(ircOutput: msgStr).compactMap(\.message)
    } else {
      return []
    }
  }

  /// Broadcasts status messages to all subscribers
  func broadcastStatus(_ status: IRCStreamEvent.ConnectionStatus) {
    currentStatus = status
    for (_, (_, continuation)) in subscribers {
      continuation.yield(.status(status))
    }
  }

  func requestCapabilities() async throws {
    try await sendMsg(.capabilities([.tags, .commands]))

    let success = try await receiveMsg().contains {
      if case .capabilities = $0 { true } else { false }
    }

    if !success {
      throw IRCError.failedToConnect
    }
  }

  func authenticate() async throws {
    try await sendMsg(.pass(pass: Constants.defaultPassword))
    try await sendMsg(.nick(name: Constants.defaultUsername))
  }
}

// MARK: - Dependency Registration

private enum IRCClientKey: DependencyKey {
  static let liveValue: any IRCStreaming = IRCClient()
}

extension DependencyValues {
  var ircClient: any IRCStreaming {
    get { self[IRCClientKey.self] }
    set { self[IRCClientKey.self] = newValue }
  }
}
