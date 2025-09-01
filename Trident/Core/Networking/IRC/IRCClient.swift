import Foundation
import TwitchIRC

actor IRCClient: IRCClientType {
  private lazy var websocket: URLSessionWebSocketTask = {
    guard let url = URL(string: "wss://irc-ws.chat.twitch.tv:443") else {
      fatalError("Invalid IRC WebSocket URL")
    }

    return URLSession.shared.webSocketTask(with: url)
  }()

  private var joinedChannels: Set<String> = []
  private var continuation: IRCMessageStream.Continuation?

  func connect() async throws -> IRCMessageStream {
    if websocket.closeCode != .invalid || websocket.state == .suspended {
      websocket.resume()
      try await requestCapabilities()
      try await authenticate()
    }

    let (stream, continuation) = IRCMessageStream.makeStream()
    self.continuation = continuation

    startReceiving()
    return stream
  }

  func disconnect() {
    Task {
      print("Closing")
      try? await self.partAll()
      continuation?.finish()
    }
    // websocket.cancel(with: .goingAway, reason: .none)
    // joinedChannels = []
    // continuation = nil
  }

  func join(to channel: String) async throws {
    guard !joinedChannels.contains(channel) else { return }
    try await sendMsg(.join(to: channel))
  }

  func part(from channel: String) async throws {
    guard joinedChannels.contains(channel) else { return }
    try await sendMsg(.part(from: channel))
  }

  func partAll() async throws {
    for chan in joinedChannels {
      try await part(from: chan)
    }
  }
}

// MARK: - Helpers

extension IRCClient {
  private func requestCapabilities() async throws {
    try await sendMsg(.capabilities([.tags, .commands]))

    let success = try await receiveMsg().contains {
      if case .capabilities = $0 { true } else { false }
    }

    if !success {
      throw IRCError.failedToConnect
    }
  }

  private func authenticate() async throws {
    try await sendMsg(.pass(pass: "SCHMOOPIIE"))
    try await sendMsg(.nick(name: "justinfan28264"))

    let success = try await receiveMsg().contains {
      if case .connectionNotice = $0 { true } else { false }
    }

    if !success {
      throw IRCError.failedToConnect
    }
  }

  private func sendMsg(_ twitchMessage: OutgoingMessage) async throws {
    try await websocket.send(.string(twitchMessage.serialize()))
  }

  private func receiveMsg() async throws -> [IncomingMessage] {
    let result = try await websocket.receive()
    if case .string(let msgStr) = result {
      return IncomingMessage.parse(ircOutput: msgStr).compactMap(\.message)
    } else {
      return []
    }
  }

  private func startReceiving() {
    Task {
      var isAlive = true

      while isAlive {
        do {
          let messages = try await receiveMsg()
          for msg in messages {
            switch msg {
            case .ping:
              try await sendMsg(.pong)
            case .join(let join):
              joinedChannels.insert(join.channel)
              continuation?.yield(msg)
            case .part(let part):
              joinedChannels.remove(part.channel)
              continuation?.yield(msg)
            default:
              continuation?.yield(msg)
            }
          }
        } catch {
          continuation?.finish(throwing: error)
          isAlive = false
        }
      }
    }
  }
}
